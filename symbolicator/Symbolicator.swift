/*

Created by Tomaz Kragelj on 9.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class Symbolicator {
	func symbolicate(_ files: Array<String>, archivesPath: String) {
		print("Symbolizing \(files.count) crash logs...")
		
		let archiveHandler = ArchiveHandler(path: archivesPath)
		let symbolicator = FileSymbolicator()
		
		for filename in files {
			// Prepare full path to crash log and bail out if it doesn't exist.
			print("")
			print("Symbolizing \(filename)...")
			let path: String = (filename as NSString).standardizingPath
			if !FileManager.default.fileExists(atPath: path) {
				print("ERROR: file doesn't exist!")
				continue
			}
			
			// Load contents of the file into string and bail out if it doesn't work.
			do {
				let original = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
				
				// Symbolicate the crash log.
				if let symbolized = symbolicator.symbolicate(filename, contents: original, archiveHandler: archiveHandler) {
					if settings.dryRun {
						continue
					}
					
					if symbolized == original {
						continue
					}
					
					do {
						try symbolized.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
						print("File overwritted with symbolized data")
					} catch {
						print("ERROR: failed saving symbolized contents: \(error)")
					}
				}
			} catch {
				print("ERROR: Failed reading contents of \((path as NSString).lastPathComponent): \(error)")
				continue
			}
		}
	}
}
