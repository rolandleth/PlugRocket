//
//  Sandbox.swift
//  PlugRocket
//
//  Created by Roland Leth on 15/12/15.
//  Copyright © 2015 Roland Leth. All rights reserved.
//

import Foundation
import Cocoa

struct Sandbox {
	
	enum Location {
		case Plugins
		case Xcode
	}
	
	static let openPanel: NSOpenPanel = {
		let op = NSOpenPanel()
		
		op.message = "In order to update your plug-ins, we require permission to access their folder, located at\n\(Utils.cleanedPluginsURL)"
		op.canCreateDirectories    = false
		op.canChooseFiles          = false
		op.canChooseDirectories    = true
		op.allowsMultipleSelection = false
		op.showsHiddenFiles        = false
		op.prompt                  = "Allow"
		op.title                   = "Allow access"
		op.extensionHidden         = true
		op.directoryURL            = NSURL(string: Utils.pluginsURL)
		
		return op
	}()
	
	static func runScriptFor(location: Location) -> String? {
		let script = location == .Plugins ? "plugins_script" : "xcode_uuid_script"
		
		let task = NSTask()
		task.launchPath = "/usr/bin/ruby"
		task.arguments = [
			NSBundle.mainBundle().pathForResource(script, ofType: "rb")!,
			Utils.cleanedPluginsURL
		]
		
		let pipe = NSPipe()
		task.standardOutput = pipe
		task.launch()
		
		let resultData = pipe.fileHandleForReading.readDataToEndOfFile()
		let resultString = String(data: resultData, encoding: NSUTF8StringEncoding)
		
		return resultString
	}
	
	// I was afraid the app would need permission to read from Xcode's contents.
	// Apparently not, but I just left the logic here, for an unexpected future.
	static func askForSandboxPermissionFor(location: Location, success: () -> Void, failure: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			let bookmarkURL = self.bookmarkedURLFor(location)
			
			guard bookmarkURL.absoluteString != "failed" && bookmarkURL.absoluteString != "stale" else {
				presentOpenPanelFor(location, success: success, failure: failure)
				return
			}
			
			bookmarkURL.startAccessingSecurityScopedResource()
			success()
		}
	}
	
	private static func bookmarkedURLFor(location: Location) -> NSURL {
		var staleBookmark: ObjCBool = false
		guard
			let bookmarkData = Utils.userDefaults.dataForKey(Utils.pluginsURLBookmarkKey),
			let url = try? NSURL(byResolvingBookmarkData: bookmarkData,
				options: .WithSecurityScope,
				relativeToURL: nil,
				bookmarkDataIsStale: &staleBookmark
			)
			else {
				return NSURL(string: "failed")!
		}
		
		guard !staleBookmark else { return NSURL(string: "stale")! }
		
		return url
	}
	
	private static func presentOpenPanelFor(location: Location, success: () -> Void, failure: () -> Void) {
		NSApplication.sharedApplication().activateIgnoringOtherApps(true)
		let tappedButton = openPanel.runModal()
		
		guard tappedButton == NSFileHandlingPanelOKButton && openPanel.URL?.absoluteString == Utils.pluginsURL else {
			failure()
			return
		}
		
		saveBookmarkDataFor(location)
		success()
	}
	
	private static func saveBookmarkDataFor(location: Location) {
		guard
			let bookmarkData = try? NSURL(string: Utils.pluginsURL)?
				.bookmarkDataWithOptions(.WithSecurityScope,
					includingResourceValuesForKeys: nil,
					relativeToURL: nil)
			where bookmarkData != nil
			else {
				return
		}
		
		Utils.userDefaults.setObject(bookmarkData, forKey: Utils.pluginsURLBookmarkKey)
		Utils.userDefaults.synchronize()
	}
}