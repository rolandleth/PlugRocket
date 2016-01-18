//
//  Utils.swift
//  PlugRocket
//
//  Created by Roland Leth on 15/12/15.
//  Copyright © 2015 Roland Leth. All rights reserved.
//

import Foundation
import Cocoa

struct Utils {
	
	private static let updatedPluginsKey = "updatedPluginsKey"
	private static let disclaimerShownKey = "disclaimerShownKey"
	private static let closeAfterUpdateKey = "closeAfterUpdateKey"
	private static let startAtLoginKey = "startAtLoginKey"
	private static let displayTotalPluginsKey = "displayTotalPlugins"
	private static let totalPluginsKey = "totalPlugins"
	private static let xcodeUUIDKey = "xcodeUUID"
	
	static var user: String {
		return NSFileManager().currentDirectoryPath.componentsSeparatedByString("/")[2]
	}
	static var pluginsURL: String {
		return "file:///Users/\(user)/Library/Application%20Support/Developer/Shared/Xcode/Plug-ins/"
	}
	static var cleanedPluginsURL: String {
		return pluginsURL
			.stringByReplacingOccurrencesOfString("file://", withString: "")
			.stringByRemovingPercentEncoding!
	}
	static let pluginsURLBookmarkKey = "pluginsURLBookmark"
	
	
	// MARK: - UserDefaults
	
	static var disclaimerShown: Bool {
		get { return userDefaults.boolForKey(disclaimerShownKey) }
		set { userDefaults.setBool(newValue, forKey: disclaimerShownKey) }
	}
	static var closeAfterUpdate: Bool {
		get { return userDefaults.boolForKey(closeAfterUpdateKey) }
		set { userDefaults.setBool(newValue, forKey: closeAfterUpdateKey) }
	}
	static var startAtLogin: Bool {
		get { return userDefaults.boolForKey(startAtLoginKey) }
		set { userDefaults.setBool(newValue, forKey: startAtLoginKey) }
	}
	static var displayTotalPlugins: Bool {
		get { return totalPlugins > 0 && userDefaults.boolForKey(displayTotalPluginsKey) }
		set { userDefaults.setBool(newValue, forKey: displayTotalPluginsKey) }
	}
	static var totalPlugins: Int {
		get { return userDefaults.integerForKey(totalPluginsKey) }
		set { userDefaults.setInteger(newValue, forKey: totalPluginsKey) }
	}
	static var xcodeUUID: String {
		get { return userDefaults.stringForKey(xcodeUUIDKey) ?? "" }
		set { userDefaults.setObject(newValue, forKey: xcodeUUIDKey) }
	}
	static var updatedPlugins: [String] {
		get { return userDefaults.arrayForKey(updatedPluginsKey) as? [String] ?? [String]() }
		set { userDefaults.setObject(newValue, forKey: updatedPluginsKey) }
	}
	
	static var userDefaults: NSUserDefaults { return NSUserDefaults.standardUserDefaults() }
	static var darkMode: Bool { return userDefaults.stringForKey("AppleInterfaceStyle") == "Dark" }
	
	
	static func showDisclaimer(completion: () -> Void = {}) {
		let alert = NSAlert()
		alert.addButtonWithTitle("OK")
		alert.addButtonWithTitle("Cancel")
		alert.alertStyle = .InformationalAlertStyle
		alert.messageText = "Disclaimer, please read!"
		alert.informativeText = "You are about to mark all your plug-ins as being compatible with Xcode, by adding its UUID to the plug-ins' plist files. This only means that Xcode will try to load them, but their functionality remains the same.\n\nIf any of the plug-ins are not actually compatible with the new version, Xcode might crash. In case this happens, you can use the revert feature, and you should wait for an official update from the author.\n\nThis message will only be shown once."
		
		guard alert.runModal() == NSAlertFirstButtonReturn else { return }
		
		Utils.disclaimerShown = true
		Utils.userDefaults.synchronize()
		completion()
	}
	
	// MARK: - Helpers
	
	static func disabledMenuTitleWithString(string: String, font: NSFont) -> NSAttributedString {
		let attributedString = NSAttributedString(
			string: string,
			attributes: [
				NSForegroundColorAttributeName: darkMode ? NSColor(deviceWhite: 0.7, alpha: 0.6) : NSColor(deviceWhite: 0.5, alpha: 0.7),
				NSFontAttributeName: font
			]
		)
		
		return attributedString
	}
	
	static func postNotificationWithText(informativeText: String, success: Bool = false) {
		let n             = NSUserNotification()
		n.title           = success ? "Success!" : "Failed"
		n.informativeText = informativeText
		n.hasActionButton = false
		
		NSUserNotificationCenter
			.defaultUserNotificationCenter()
			.deliverNotification(n)
	}
}
