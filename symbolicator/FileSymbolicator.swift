/*

Created by Tomaz Kragelj on 10.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class FileSymbolicator {
	func symbolicate(contents: String, archiveHandler: ArchiveHandler) {
		let optionalInformation = self.extractProcessInformation(contents)
		if !optionalInformation {
			return;
		}
		
		let information = optionalInformation!
		
		// Get starting address.
		let optionalStartAddress = self.baseAddress(contents, identifier: information.identifier, version: information.version, build: information.build)
		if !optionalStartAddress {
			return
		}

		// Get the corresponding dwarf file.
		let optionalDwarfPath = archiveHandler.dwarfPathWithIdentifier(information.identifier, version: information.version, build: information.build)
		if !optionalDwarfPath {
			println("ERROR: No archive found!")
			return
		}
		
		// Find all matches in the crash log, using both, application name and identifier.
		var matches = RxMatch[]()
		matches += self.matches(contents, identifier: information.name)
		matches += self.matches(contents, identifier: information.identifier)
	}
	
	/* private */ func matches(contents: NSString, identifier: String) -> RxMatch[] {
		let pattern: NSString = "^[0-9]+\\s+\(identifier)\\s+(0x[0-9a-fA-F]+)(.+)$"
		let regex = pattern.toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)
		return contents.matchesWithDetails(regex) as RxMatch[]
	}
	
	/* private */ func baseAddress(contents: String, identifier: String, version: String, build: String) -> String? {
		let pattern: NSString = "^\\s+(0x[0-9a-fA-F]+)\\s+-\\s+(0x[0-9a-fA-F]+)\\s+[+]?\(identifier)\\s+\\(\(version)\\s*-\\s*\(build)\\)"
		let optionalMatch = pattern.toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalMatch {
			println("ERROR: Didn't find starting address for \(identifier)")
			return nil
		}
		
		let result = optionalMatch!.groups[1].value
		println("Starting address is \(result)")
		return result
	}
	
	// xcrun atos -arch x86_64
	// -o "~/Library/Developer/Xcode/Archives/2013-12-18/Startupizer 2.3.1 (1980) 18.12.13 07.49.xcarchive/dSYMs/Startupizer2.app.dSYM/Contents/Resources/DWARF/Startupizer2" 
	// -l
	
	/* private */ func extractProcessInformation(contents: String) -> (name: String, identifier: String, version: String, build: String)? {
		let optionalProcessMatch = "^Process:\\s+([^\\[]+) \\[[^\\]]+\\]".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalProcessMatch {
			println("ERROR: Process name is missing!")
			return nil
		}
		
		let optionalIdentifierMatch = "^Identifier:\\s+(.+)$".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalIdentifierMatch {
			println("ERROR: Process identifier is missing!")
			return nil
		}
		
		let optionalVersionMatch = "^Version:\\s+([^ ]+) \\(([^)]+)\\)".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalVersionMatch {
			println("ERROR: Process version and build number is missing!")
			return nil
		}
		
		let name = optionalProcessMatch!.groups[1].value
		let identifier = optionalIdentifierMatch!.groups[1].value
		let version = optionalVersionMatch!.groups[1].value
		let build = optionalVersionMatch!.groups[2].value
		
		println("Detected \(identifier) [\(name) \(version) (\(build))]")
		return (name, identifier, version, build)
	}
}
