/*

Created by Tomaz Kragelj on 9.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class Symbolicator {
	init(settings: Settings) {
		self.settings = settings
	}
	
	func symbolicate() {
		println("Symbolicating \(settings.arguments.count) crash logs...")
		for filename: AnyObject in settings.arguments {
			println("Symbolicating \(filename)...")
			let path: String = filename.stringByStandardizingPath
			if !NSFileManager.defaultManager().fileExistsAtPath(path) {
				println("ERROR: file doesn't exist!")
				continue
			}
			
			let contents: String = NSString.stringWithContentsOfFile(path)
		}
	}
	
	let settings: Settings
}
