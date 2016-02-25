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
	
	private static let updatedPluginsKey      = "updatedPluginsKey"
	private static let updatedBetaPluginsKey  = "updatedBetaPluginsKey"
	private static let disclaimerShownKey     = "disclaimerShownKey"
	private static let closeAfterUpdateKey    = "closeAfterUpdateKey"
	private static let startAtLoginKey        = "startAtLoginKey"
	private static let updateXcodeBetaKey     = "updateXcodeBetaKey"
	private static let displayTotalPluginsKey = "displayTotalPlugins"
	private static let totalPluginsKey        = "totalPlugins"
	private static let xcodeUUIDKey           = "xcodeUUID"
	private static let xcodeBetaUUIDKey       = "xcodeBetaUUID"
	
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
		set { userDefaults.setBool(newValue, forKey: disclaimerShownKey); userDefaults.synchronize() }
	}
	static var closeAfterUpdate: Bool {
		get { return userDefaults.boolForKey(closeAfterUpdateKey) }
		set { userDefaults.setBool(newValue, forKey: closeAfterUpdateKey); userDefaults.synchronize() }
	}
	static var startAtLogin: Bool {
		get { return userDefaults.boolForKey(startAtLoginKey) }
		set { userDefaults.setBool(newValue, forKey: startAtLoginKey); userDefaults.synchronize() }
	}
	static var updateXcodeBeta: Bool {
		get { return userDefaults.boolForKey(updateXcodeBetaKey) }
		set { userDefaults.setBool(newValue, forKey: updateXcodeBetaKey); userDefaults.synchronize() }
	}
	static var displayTotalPlugins: Bool {
		get { return totalPlugins > 0 && userDefaults.boolForKey(displayTotalPluginsKey) }
		set { userDefaults.setBool(newValue, forKey: displayTotalPluginsKey); userDefaults.synchronize() }
	}
	static var totalPlugins: Int {
		get { return userDefaults.integerForKey(totalPluginsKey) }
		set { userDefaults.setInteger(newValue, forKey: totalPluginsKey); userDefaults.synchronize() }
	}
	static var xcodeUUID: String {
		get { return userDefaults.stringForKey(xcodeUUIDKey) ?? "" }
		set { userDefaults.setObject(newValue, forKey: xcodeUUIDKey); userDefaults.synchronize() }
	}
	static var xcodeBetaUUID: String {
		get { return userDefaults.stringForKey(xcodeBetaUUIDKey) ?? "" }
		set { userDefaults.setObject(newValue, forKey: xcodeBetaUUIDKey); userDefaults.synchronize() }
	}
	static var updatedPlugins: [String] {
		get { return userDefaults.arrayForKey(updatedPluginsKey) as? [String] ?? [String]() }
		set { userDefaults.setObject(newValue, forKey: updatedPluginsKey); userDefaults.synchronize() }
	}
	static var updatedBetaPlugins: [String] {
		get { return userDefaults.arrayForKey(updatedBetaPluginsKey) as? [String] ?? [String]() }
		set { userDefaults.setObject(newValue, forKey: updatedBetaPluginsKey); userDefaults.synchronize() }
	}
	
	static var userDefaults: NSUserDefaults { return NSUserDefaults.standardUserDefaults() }
	static var darkMode: Bool { return userDefaults.stringForKey("AppleInterfaceStyle") == "Dark" }
	
	
	// MARK: - Helpers
	
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
	
	static func delay(delay: Double, closure: () -> ()) {
		dispatch_after(
			dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
			dispatch_get_main_queue(),
			closure
		)
	}
}
