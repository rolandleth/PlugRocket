//
//  AppDelegate.swift
//  PlugRocketHelper
//
//  Created by Roland Leth on 10/1/16.
//  Copyright © 2016 Roland Leth. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		let workspace = NSWorkspace.sharedWorkspace()
		let runningApps = workspace.runningApplications
		var alreadyRunning = false
		for app in runningApps where app.bundleIdentifier == "com.rolandleth.PlugRocket" {
			alreadyRunning = true
			break
		}
		
		defer { NSApp.terminate(nil) }
		guard !alreadyRunning else { return }
		
		let basePath = NSBundle.mainBundle().bundlePath as NSString
		var newPath = basePath.stringByDeletingLastPathComponent
		if newPath.containsString("Library") {
			newPath = (newPath as NSString).stringByDeletingLastPathComponent
		}
		newPath = (newPath as NSString).stringByDeletingLastPathComponent
		newPath = (newPath as NSString).stringByDeletingLastPathComponent
		
		// http://rhult.github.io/articles/sandboxed-launch-on-login/
		if !workspace.launchApplication(newPath) {
			let directPath = (newPath as NSString).stringByAppendingPathComponent("Contents/MacOS/PlugRocket.app")
			workspace.launchApplication(directPath)
		}
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
}

