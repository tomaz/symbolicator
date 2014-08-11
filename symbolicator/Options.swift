/*

Created by Tomaz Kragelj on 11.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class Options: GBOptionsHelper {
	override init() {
		super.init()
		
		self.applicationVersion = { "1.0" }
		self.applicationBuild = { "99" }
		self.printHelpHeader = { "Usage: %APPNAME [OPTIONS] <crash log paths separated by space>\nExample: %APPNAME crashlog1.crash \"~/Downloads/some other crash.txt\"" }
		
		self.registerSeparator("OPTIONS")
		self.registerOption(0, long: settingXcodeArchivesKey, description: "Xcode archives location", flags: GBOptionFlags.RequiredValue)
		self.registerOption(0, long: settingsPrintHelpKey, description: "Print this help and exit", flags: GBOptionFlags.NoValue)
	}
}