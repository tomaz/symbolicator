/*

Created by Tomaz Kragelj on 9.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

class Settings: GBSettings {
	init() {
		// First setup factory defaults.
		let defaults = Settings(name: "Factory Defaults", parent: nil)
		defaults.xcodeArchivesFolder = "~/Library/Developer/Xcode/Archives"
		
		// Now return the settings using factory defaults as their parent
		super.init(name: "FactoryDefaults", parent: defaults)
	}
	
	init(name: String, parent: GBSettings?) {
		super.init(name: name, parent: parent)
	}
	
	var xcodeArchivesFolder: String {
		get { return self.objectForKey(settingXcodeArchivesKey) as String }
		set { self.setObject(newValue, forKey: settingXcodeArchivesKey) }
	}
	
	var printHelp: Bool {
		get { return self.boolForKey(settingsPrintHelpKey) }
		set { self.setBool(newValue, forKey: settingsPrintHelpKey) }
	}
}

let settingXcodeArchivesKey = "archives"
let settingsPrintHelpKey = "help"
