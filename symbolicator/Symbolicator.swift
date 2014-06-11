/*

Created by Tomaz Kragelj on 9.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class Symbolicator {
	func symbolicate(files: Array<String>, archivesPath: String) {
		println("Symbolicating \(files.count) crash logs...")
		
		let archiveHandler = ArchiveHandler(path: archivesPath)
		let symbolicator = FileSymbolicator()
		
		for filename in files {
			// Prepare full path to crash log and bail out if it doesn't exist.
			println()
			println("Symbolicating \(filename)...")
			let path: String = filename.stringByStandardizingPath
			if !NSFileManager.defaultManager().fileExistsAtPath(path) {
				println("ERROR: file doesn't exist!")
				continue
			}
			
			// Load contents of the file into string and bail out if it doesn't work.
			let optionalContents = String.stringWithContentsOfFile(path, encoding: NSUTF8StringEncoding, error: nil)
			if (!optionalContents) {
				println("ERROR: can't read contents of \(path.lastPathComponent)!")
				continue
			}
			
			// Symbolicate the crash log.
			if let symbolized = symbolicator.symbolicate(optionalContents!, archiveHandler: archiveHandler) {
				if !symbolized.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil) {
					println("ERROR: failed saving symbolized contents!")
					continue
				}
			}
			
			println("Finished!")
		}
	}
}
