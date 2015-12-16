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
	
	static func saveBookmarkDataFor(location: Location) {
		// I was afraid the app would need permission to read from Xcode's contents.
		// Apparently not, but I just left this here, for an unexpected future.
		let URL = location == .Plugins ? Utils.pluginsURL : Utils.xcodeURL
		let key = location == .Plugins ? Utils.pluginsURLBookmarkKey : Utils.xcodeURLBookmarkKey
		
		guard
			let bookmarkData = try? NSURL(string: URL)?
				.bookmarkDataWithOptions(.WithSecurityScope,
					includingResourceValuesForKeys: nil,
					relativeToURL: nil)
			where bookmarkData != nil
			else {
				return
		}
		
		Utils.userDefaults.setObject(bookmarkData, forKey: key)
		Utils.userDefaults.synchronize()
	}
	
	static func bookmarkedURLFor(location: Location) -> NSURL {
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
	
	static func presentOpenPanelFor(location: Location, success: () -> Void, failure: () -> Void) {
		NSApplication.sharedApplication().activateIgnoringOtherApps(true)
		
		let tappedButton = openPanel.runModal()
		
		guard tappedButton == NSFileHandlingPanelOKButton && openPanel.URL?.absoluteString == Utils.pluginsURL else {
			failure()
			return
		}
		
		saveBookmarkDataFor(location)
		success()
	}
}