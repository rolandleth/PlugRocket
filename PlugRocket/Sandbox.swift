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
	
	enum XcodeType: String {
		case Production = "Xcode"
		case Beta       = "Xcode-beta"
	}
	
	static let genericErrorMessage = "Something went wrong."
	
	static let openPanel: NSOpenPanel = {
		let op = NSOpenPanel()
		
		op.canCreateDirectories    = false
		op.canChooseDirectories    = false
		op.showsHiddenFiles        = false
		op.prompt                  = "Allow"
		op.title                   = "Allow access"
		op.extensionHidden         = true
		op.directoryURL            = NSURL(string: Utils.pluginsURL)
		
		return op
	}()
	
	static func runXcodeScriptFor(xcode: XcodeType) -> String? {
		let script: String = {
			switch xcode {
			case .Production: return "xcode_uuid_script"
			case .Beta: return "xcode_beta_uuid_script"
			}
		}()
		
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
	
	
	// MARK: - File handling
	
	static func pluginPlists() -> ([NSURL], success: Bool) {
		let manager = NSFileManager.defaultManager()
		guard
			let pluginURL = NSURL(string: Utils.pluginsURL),
			let plists = try? manager.contentsOfDirectoryAtURL(pluginURL,
				includingPropertiesForKeys: [],
				options: .SkipsHiddenFiles) else {
					Utils.postNotificationWithText(genericErrorMessage)
					return ([NSURL](), success: false)
		}
		
		return (plists.map() {
			return $0.URLByAppendingPathComponent("Contents/Info.plist")
		}, success: true)
	}
	
	static func revertPlugins(plugins: [NSURL]? = nil, xcode: XcodeType) -> (Int, Int, success: Bool) {
		return updatePlugins(plugins, xcode: xcode, revert: true)
	}
	
	static func updatePlugins(plugins: [NSURL]? = nil, xcode: XcodeType) -> (Int, Int, success: Bool) {
		return updatePlugins(plugins, xcode: xcode, revert: false)
	}
	
	private static func updatePlugins(plugins: [NSURL]? = nil, xcode: XcodeType, revert reverting: Bool) -> (Int, Int, success: Bool) {
		let result = pluginPlists()
		let plists = plugins ?? result.0
		
		guard result.success else {
			Utils.postNotificationWithText(genericErrorMessage)
			return (0, 0, success: false)
		}
		
		var pluginsUpdated = 0
		var pluginsUptodate = 0
		
		for plist in plists.reverse() {
			guard
				let plistDictionary = NSMutableDictionary(contentsOfURL: plist),
				var plistUUIDs = plistDictionary["DVTPlugInCompatibilityUUIDs"] as? [String] else {
					continue
			}
			
			var pluginUpdated = false
			let xcodeUUID = (xcode == .Production) ? Utils.xcodeUUID : Utils.xcodeBetaUUID
			
			if reverting {
				if let UUIDIndex = plistUUIDs.indexOf(xcodeUUID) {
					pluginUpdated = true
					plistUUIDs.removeAtIndex(UUIDIndex)
				}
				
				if xcode == .Production,
					let URLIndex = Utils.updatedPlugins.indexOf(plist.absoluteString) {
						Utils.updatedPlugins.removeAtIndex(URLIndex)
				}
				else if xcode == .Beta,
					let betaURLIndex = Utils.updatedBetaPlugins.indexOf(plist.absoluteString) {
						Utils.updatedBetaPlugins.removeAtIndex(betaURLIndex)
				}
			}
			else {
				if !plistUUIDs.contains(xcodeUUID) {
					pluginUpdated = true
					plistUUIDs.append(xcodeUUID)
					
					if xcode == .Production {
						Utils.updatedPlugins.append(plist.absoluteString)
					}
					else {
						Utils.updatedBetaPlugins.append(plist.absoluteString)
					}
				}
			}
			
			if pluginUpdated {
				pluginsUpdated += 1
			}
			else {
				pluginsUptodate += 1
			}
			
			plistDictionary["DVTPlugInCompatibilityUUIDs"] = plistUUIDs
			plistDictionary.writeToURL(plist, atomically: true)
		}
		
		return (pluginsUpdated, pluginsUptodate, success: true)
	}

/*
	// MARK: - Bookmarks
	
	enum Location {
	  case Plugins
	  case Xcode
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
		NSApp.activateIgnoringOtherApps(true)
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseFiles          = false
		openPanel.message                 = "In order to update your plug-ins, we require permission to access their folder, located at\n\(Utils.cleanedPluginsURL)"
		
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
*/
}