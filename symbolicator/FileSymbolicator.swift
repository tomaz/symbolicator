/*

Created by Tomaz Kragelj on 10.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class FileSymbolicator {
	func symbolicate(contents: String, archiveHandler: ArchiveHandler) {
		if !self.extractProcessInformation(contents) { return }
		
		let optionalDwarfPath = archiveHandler.dwarfPathWithIdentifier(self.processIdentifier, version: self.processVersion, build: self.processBuildNumber)
		if (!optionalDwarfPath) {
			println("ERROR: No archive found!")
			return
		}
		
	}
	
	// xcrun atos -arch x86_64
	// -o "~/Library/Developer/Xcode/Archives/2013-12-18/Startupizer 2.3.1 (1980) 18.12.13 07.49.xcarchive/dSYMs/Startupizer2.app.dSYM/Contents/Resources/DWARF/Startupizer2" 
	// -l
	
	/* private */ func extractProcessInformation(contents: String) -> Bool {
		let optionalProcessMatch = "^Process:\\s+([^\\[]+) \\[[^\\]]+\\]".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalProcessMatch {
			println("ERROR: Process name is missing!")
			return false
		}
		
		let optionalIdentifierMatch = "^Identifier:\\s+(.+)$".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalIdentifierMatch {
			println("ERROR: Process identifier is missing!")
			return false
		}
		
		let optionalVersionMatch = "^Version:\\s+([^ ]+) \\(([^)]+)\\)".toRxWithOptions(NSRegularExpressionOptions.AnchorsMatchLines)!.firstMatchWithDetails(contents)
		if !optionalVersionMatch {
			println("ERROR: Process version and build number is missing!")
			return false
		}
		
		self.processName = optionalProcessMatch!.groups[1].value
		self.processIdentifier = optionalIdentifierMatch!.groups[1].value
		self.processVersion = optionalVersionMatch!.groups[1].value
		self.processBuildNumber = optionalVersionMatch!.groups[2].value
		
		println("Detected \(self.processIdentifier) [\(self.processName) \(self.processVersion) (\(self.processBuildNumber))]")
		return true
	}

	/* private */ var processName: String = ""
	/* private */ var processIdentifier: String = ""
	/* private */ var processVersion: String = ""
	/* private */ var processBuildNumber: String = ""
}
