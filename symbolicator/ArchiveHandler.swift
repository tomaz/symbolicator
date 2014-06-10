/*

Created by Tomaz Kragelj on 10.06.2014.
Copyright (c) 2014 Gentle Bytes. All rights reserved.

*/

import Foundation

class ArchiveHandler {
	init(path: String) {
		self.dwarfPathsByIdentifiers = Dictionary()
		self.basePath = path
	}
	
	func dwarfPathWithIdentifier(identifier: String, version: String, build: String) -> String? {
		let archiveKey = self.dwarfKeyWithIdentifier(identifier, version: version, build: build)
		
		// If this archive was already parsed, return the path.
		let optionalPath = self.dwarfPathsByIdentifiers[archiveKey]
		if optionalPath { return optionalPath! }
		
		// Otherwise scan all archives for the given version.
		let manager = NSFileManager.defaultManager()
		let fullBasePath = self.basePath.stringByStandardizingPath
		manager.enumerateDirectoriesAtPath(fullBasePath) {
			dateFolder in
			manager.enumerateDirectoriesAtPath(dateFolder) {
				buildFolder in
				
				// If there's no plist file at the given path, ignore it.
				let plistPath = buildFolder.stringByAppendingPathComponent("Info.plist")
				if !manager.fileExistsAtPath(plistPath) { return }
				
				// Load plist into dictionary.
				let plistData = NSData.dataWithContentsOfFile(plistPath, options: NSDataReadingOptions.DataReadingUncached, error: nil)
				let plistContents: AnyObject = NSPropertyListSerialization.propertyListWithData(plistData, options: 0, format: nil, error: nil)
				
				// Read application properties.
				let applicationProperties: AnyObject = plistContents.objectForKey("ApplicationProperties")
				let applicationPath = applicationProperties.objectForKey("ApplicationPath") as String
				let applicationIdentifier = applicationProperties.objectForKey("CFBundleIdentifier") as String
				let applicationVersion = applicationProperties.objectForKey("CFBundleShortVersionString") as String
				let applicationBuild = applicationProperties.objectForKey("CFBundleVersion") as String
				
				// Prepare path components.
				let applicationFilename = applicationPath.lastPathComponent
				let applicationName = applicationFilename.stringByDeletingPathExtension
				
				// Add entry to dwarf keys.
				let dwarfKey = self.dwarfKeyWithIdentifier(applicationIdentifier, version: applicationVersion, build: applicationBuild)
				let dwarfPath = "\(buildFolder)/dSYMs/\(applicationFilename).dSYM/Contents/Resources/DWARF/\(applicationName)"
				self.dwarfPathsByIdentifiers[dwarfKey] = dwarfPath
			}
		}
		
		if let path = self.dwarfPathsByIdentifiers[archiveKey] {
			return path
		}
		
		return nil
	}
	
	/* private */ func dwarfKeyWithIdentifier(identifier: String, version: String, build: String) -> String {
		return "\(identifier) \(version) \(build)"
	}
	
	// xcrun atos -arch x86_64
	// -o "~/Library/Developer/Xcode/Archives/2013-12-18/Startupizer 2.3.1 (1980) 18.12.13 07.49.xcarchive/dSYMs/Startupizer2.app.dSYM/Contents/Resources/DWARF/Startupizer2"
	// -l
	
	/* private */ let basePath: String
	/* private */ var dwarfPathsByIdentifiers: Dictionary<String, String>
}

extension NSFileManager {
	func enumerateDirectoriesAtPath(path: String, block: (path: String) -> Void) {
		let subpaths = self.contentsOfDirectoryAtPath(path, error: nil) as String[]
		for subpath in subpaths {
			let fullPath = path.stringByAppendingPathComponent(subpath)
			if !self.isDirectoryAtPath(fullPath) { continue }
			block(path: fullPath)
		}
	}
	
	func isDirectoryAtPath(path: NSString) -> Bool {
		let attributes = self.attributesOfItemAtPath(path, error: nil)
		if attributes[NSFileType] as? NSObject == NSFileTypeDirectory {
			return true
		}
		return false
	}
}
