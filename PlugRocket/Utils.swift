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
	
	private static let closeAfterUpdateKey = "closeAfterUpdateKey"
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
	
	static var closeAfterUpdate: Bool {
		get { return userDefaults.boolForKey(closeAfterUpdateKey) }
		set { userDefaults.setBool(newValue, forKey: closeAfterUpdateKey) }
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
	
	static var userDefaults: NSUserDefaults { return NSUserDefaults.standardUserDefaults() }
	static var darkMode: Bool { return userDefaults.stringForKey("AppleInterfaceStyle") == "Dark" }
	
	
	// MARK: - Helpers
	
	static func disabledMenuTitleWithString(string: String, font: NSFont) -> NSAttributedString {
		let attributedString = NSAttributedString(
			string: string,
			attributes: [
				NSForegroundColorAttributeName: darkMode ? NSColor(deviceWhite: 0.7, alpha: 0.6) : NSColor(deviceWhite: 0.3, alpha: 0.6),
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
