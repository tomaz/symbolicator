/*

Created by Tomaz Kragelj on 10.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

typealias CrashlogInformation = (name: String, identifier: String, version: String, build: String, architecture: String)

class FileSymbolicator {
	
	func symbolicate(_ path: String, contents: String, archiveHandler: ArchiveHandler) -> String? {
		// Extract all information about the process that crashed. Exit if not possible.
		guard let information = extractProcessInformation(contents) else {
			return nil
		}
		
		// Store parameters for later use.
		self.path = path
		self.archiveHandler = archiveHandler
		
		// Prepare array of all lines needed for symbolication.
		let matches = linesToSymbolicate(contents as NSString)
		print("Found \(matches.count) lines that need symbolication")
		
		// Symbolicate all matches.
		return symbolicateString(contents, information: information, matches: matches)
	}
	
	fileprivate func linesToSymbolicate(_ contents: NSString) -> [RxMatch] {
		let pattern = "^[0-9]+?\\s+?([^?]+?)\\s+?(0x[0-9a-fA-F]+?)\\s+?(.+?)$"
		let regex = pattern.toRx(options: .anchorsMatchLines)
		
		// Find all matches.
		let matches = contents.matches(withDetails: regex) as! [RxMatch]
		let whitespace = CharacterSet.whitespaces
		
		// Filter just the ones that have a hex number instead of symbol.
		return matches.filter { match in
			guard let symbolOrAddress = (match.groups[3] as! RxMatchGroup).value else {
				return false
			}
			
			// Only contains hexadecimal address.
			if symbolOrAddress.hasPrefix("0x") {
				return true
			}
			
			// Contains "binary + address" - for example "Startupizer2 + 608348"
			let binary = (match.groups[1] as! RxMatchGroup).value.trimmingCharacters(in: whitespace)
			if symbolOrAddress.contains(binary) && symbolOrAddress.contains("+") {
				return true
			}
			
			return false
		}
	}
	
	fileprivate func symbolicateString(_ contents: String, information: CrashlogInformation, matches: [RxMatch]) -> String {
		// Symbolicate all matches. Each entry corresponds to the same match in given array.
		let whitespace = CharacterSet.whitespacesAndNewlines
		var result = contents
		numberOfSymbolizedAddresses = 0
		for match in matches {
			// Add delimiter above each symbolication when verbose mode is on.
			if settings.printVerbose {
				print("")
			}
			
			// Prepare binary and base address.
			let binary = (match.groups[1] as! RxMatchGroup).value!.trimmingCharacters(in: whitespace)
			guard let baseAddress = baseAddressForSymbolication(contents, identifier: binary) else {
				continue
			}
			
			// Prepare dwarf path for this binary.
			guard let dwarfPath = archiveHandler.dwarfPathWithIdentifier(binary, version: information.version, build: information.build) else {
				print("> \(binary): missing DWARF file!")
				continue
			}
			
			// Symbolicate addresses.
			let address = (match.groups[2] as! RxMatchGroup).value!
			guard let symbolizedAddress = symbolicateAddresses(baseAddress, architecture: information.architecture, dwarfPath: dwarfPath, addresses: [address]).first else {
				print("> \(binary) \(address): no symbol found!")
				continue
			}

			// If no symbol is available, ignore.
			let originalString = match.value!
			if (symbolizedAddress.characters.count == 0) {
				print("> \(binary) \(address): no symbol found!")
				continue
			}
			
			// Replace all occurrences within the file.
			let locationInOriginalString = (match.groups[3] as! RxMatchGroup).range.location - match.range.location
			let replacementPrefix = originalString.substring(to: originalString.characters.index(originalString.startIndex, offsetBy: locationInOriginalString))
			let replacementString = "\(replacementPrefix)\(symbolizedAddress)"
			result = result.replacingOccurrences(of: originalString, with: replacementString)
			print("> \(binary) \(address): \(symbolizedAddress)")
			numberOfSymbolizedAddresses += 1
		}
		
		if matches.count > 0 {
			if settings.printVerbose {
				print("")
			}
			
			let filename = (path as NSString).lastPathComponent
			if numberOfSymbolizedAddresses == matches.count {
				print("All \(matches.count) \(filename) addresses symbolized")
			} else {
				print("\(numberOfSymbolizedAddresses) of \(matches.count) \(filename) addresses symbolized")
			}
		}
		
		return result
	}
	
	fileprivate func baseAddresses(_ contents: String, matches: [RxMatch]) -> [String: (String, [RxMatch])] {
		let ignoredChars = CharacterSet.whitespacesAndNewlines
		
		var result = [String: (String, [RxMatch])]()
		
		// Prepare an array of base addresses per binary.
		for match in matches {
			// Prepare binary and address information.
			let binary = (match.groups[1] as! RxMatchGroup).value.trimmingCharacters(in: ignoredChars)
			if binary.characters.count == 0 {
				continue
			}
			
			// If we already matched this pair, reuse it.
			if var existingEntry = result[binary] {
				var matches = existingEntry.1
				matches.append(match)
				existingEntry.1 = matches
				continue
			}
			
			// Otherwise gather it from crash log. Ignore if no match is found.
			guard let baseAddress = baseAddressForSymbolication(contents, identifier: binary) else {
				continue
			}
			
			// Add address to previous addresses so we don't have to repeat.
			result[binary] = (baseAddress, [match])
		}
		
		return result
	}
	
	fileprivate func symbolicateAddresses(_ baseAddress: String, architecture: String, dwarfPath: String, addresses: [String]) -> [String] {
		let arch = architecture.lowercased().replacingOccurrences(of: "-", with: "_")
		let stdOutPipe = Pipe()
		let stdErrPipe = Pipe()
		let task = Process()
		task.launchPath = "/usr/bin/xcrun"
		task.arguments = ["atos", "-arch", arch, "-o", dwarfPath, "-l", baseAddress] + addresses
		task.standardOutput = stdOutPipe
		task.standardError = stdErrPipe
		task.launch()
		task.waitUntilExit()
		
		let translatedData = stdOutPipe.fileHandleForReading.readDataToEndOfFile()
		let translatedString = NSString(data: translatedData, encoding: String.Encoding.ascii.rawValue)!
		
		if settings.printVerbose {
			// Print command line for simpler replication in
			let whitespace = CharacterSet.whitespaces
			let arguments = task.arguments! as [String]
			let cmdline = arguments.reduce("") {
				if let _ = $1.rangeOfCharacter(from: whitespace) {
					return "\($0) \"\($1)\""
				}
				return "\($0) \($1)"
			}
			print("\(task.launchPath!) \(cmdline)");
		}
		
		// If there's some error, print it.
		let errorData = stdErrPipe.fileHandleForReading.readDataToEndOfFile()
		if let errorString = NSString(data: errorData, encoding: String.Encoding.ascii.rawValue), errorString.length > 0 {
			print("\(errorString)")
		}
		
		return translatedString.components(separatedBy: "\n") as [String]
	}
	
	fileprivate func baseAddressForSymbolication(_ contents: String, identifier: String) -> String? {
		// First attempt to find the whole identifier.
		let pattern = "^\\s+(0x[0-9a-fA-F]+)\\s+-\\s+(0x[0-9a-fA-F]+)\\s+[+]?\(identifier)\\s+"
		if let regex = pattern.toRx(options: .anchorsMatchLines), let match = regex.firstMatch(withDetails: contents) {
			return (match.groups[1] as! RxMatchGroup).value
		}
		
		// If this fails, fall down to generic search for binaries that include the given identifier.
		let falldownPattern = "^\\s+(0x[0-9a-fA-F]+)\\s+-\\s+(0x[0-9a-fA-F]+)\\s+[+]?([^\\s]+)\\s+"
		if let regex = falldownPattern.toRx(options: .anchorsMatchLines), let matches = regex.matches(withDetails: contents) {
			for match in matches as! [RxMatch] {
				let binary = (match.groups[3] as! RxMatchGroup).value
				if (binary?.contains(identifier))! {
					return (match.groups[1] as! RxMatchGroup).value
				}
			}
		}
		
		print("WARNING: Didn't find starting address for \(identifier)")
		return nil
	}
	
	fileprivate func extractProcessInformation(_ contents: String) -> CrashlogInformation? {
		let optionalProcessMatch = "^Process:\\s+([^\\[]+) \\[[^\\]]+\\]".toRx(options: NSRegularExpression.Options.anchorsMatchLines)!.firstMatch(withDetails: contents)
		if (optionalProcessMatch == nil) {
			print("ERROR: Process name is missing!")
			return nil
		}
		
		let optionalIdentifierMatch = "^Identifier:\\s+(.+)$".toRx(options: NSRegularExpression.Options.anchorsMatchLines)!.firstMatch(withDetails: contents)
		if (optionalIdentifierMatch == nil) {
			print("ERROR: Process identifier is missing!")
			return nil
		}
		
		let optionalVersionMatch = "^Version:\\s+([^ ]+) \\(([^)]+)\\)$".toRx(options: NSRegularExpression.Options.anchorsMatchLines)!.firstMatch(withDetails: contents)
		if (optionalVersionMatch == nil) {
			print("ERROR: Process version and build number is missing!")
			return nil
		}
		
		let optionalArchitectureMatch = "^Code Type:\\s+([^ \\r\\n]+)".toRx(options: NSRegularExpression.Options.anchorsMatchLines)!.firstMatch(withDetails: contents);
		if (optionalArchitectureMatch == nil) {
			print("ERROR: Process architecture value is missing!")
			return nil
		}

		let processGroup1 = optionalProcessMatch!.groups[1] as! RxMatchGroup
		let identifierGroup1 = optionalIdentifierMatch!.groups[1] as! RxMatchGroup
		let versionGroup1 = optionalVersionMatch!.groups[1] as! RxMatchGroup
		let versionGroup2 = optionalVersionMatch!.groups[2] as! RxMatchGroup
		let architectureGroup1 = optionalArchitectureMatch!.groups[1] as! RxMatchGroup
		
		let name = processGroup1.value as String
		let identifier = identifierGroup1.value as String
		let version = versionGroup1.value as String
		let build = versionGroup2.value as String
		let architecture = architectureGroup1.value as String
		
		print("Detected \(identifier) \(architecture) [\(name) \(version) (\(build))]")
		return (name, identifier, version, build, architecture)
	}
	
	fileprivate var archiveHandler: ArchiveHandler!
	fileprivate var path: String!
	fileprivate var numberOfSymbolizedAddresses = 0
}
