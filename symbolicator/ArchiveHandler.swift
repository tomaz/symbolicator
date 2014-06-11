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
		// If we don't have any dwarf files scanned, do so now.
		if self.dwarfPathsByIdentifiers.count == 0 {
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
					let applicationInfo = self.applicationInformationWithInfoPlist(plistContents)
					let applicationName = applicationInfo.name.stringByDeletingPathExtension

					// Add entry to dwarf keys.
					let dwarfKey = self.dwarfKeyWithIdentifier(applicationInfo.identifier, version: applicationInfo.version, build: applicationInfo.build)
					let dwarfPath = "\(buildFolder)/dSYMs/\(applicationInfo.name).dSYM/Contents/Resources/DWARF/\(applicationName)"
					self.dwarfPathsByIdentifiers[dwarfKey] = dwarfPath
				}
			}
		}
		
		// Try to get dwarf path using build number first. If found, use it.
		let archiveKey = self.dwarfKeyWithIdentifier(identifier, version: version, build: build)
		if let result = self.dwarfPathsByIdentifiers[archiveKey] {
			println("Matched archive at \(result)")
			return result
		}
		
		// Try to use generic "any build" for given version (older versions of Xcode didn't save build number to archive plist). If found, use it.
		let genericArchiveKey = self.dwarfKeyWithIdentifier(identifier, version: version, build: "")
		if let result = self.dwarfPathsByIdentifiers[genericArchiveKey] {
			println("Matched archive at \(result)")
			return result
		}
		
		// If there's no archive match, return nil
		return nil
	}
	
	/* private */ func applicationInformationWithInfoPlist(plistContents: AnyObject) -> (name: String, identifier: String, version: String, build: String) {
		var applicationName = ""
		var applicationIdentifier = ""
		var applicationVersion = ""
		var applicationBuild = ""
		
		if let applicationProperties: AnyObject = plistContents.objectForKey("ApplicationProperties") {
			if let path = applicationProperties.objectForKey("ApplicationPath") as? String {
				applicationName = path.lastPathComponent
			}
			if let identifier = applicationProperties.objectForKey("CFBundleIdentifier") as? String {
				applicationIdentifier = identifier
			}
			if let version = applicationProperties.objectForKey("CFBundleShortVersionString") as? String {
				applicationVersion = version
			}
			if let build = applicationProperties.objectForKey("CFBundleVersion") as? String {
				applicationBuild = build
			}
		}
		
		return (applicationName, applicationIdentifier, applicationVersion, applicationBuild)
	}
	
	/* private */ func dwarfKeyWithIdentifier(identifier: String, version: String, build: String) -> String {
		if countElements(build) == 0 {
			return "\(identifier) \(version) ANYBUILD"
		}
		return "\(identifier) \(version) \(build)"
	}
	
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
