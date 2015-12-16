//
//  AppDelegate.swift
//  PlugRocket
//
//  Created by Roland Leth on 14/12/15.
//  Copyright © 2015 Roland Leth. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	private weak var window: NSWindow!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		_ = Menu()
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
}

