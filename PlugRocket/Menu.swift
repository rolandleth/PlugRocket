//
//  Menu.swift
//  PlugRocket
//
//  Created by Roland Leth on 14/12/15.
//  Copyright © 2015 Roland Leth. All rights reserved.
//

import Cocoa
import ServiceManagement

class Menu: NSMenu, NSUserNotificationCenterDelegate {

	private var updatedPlugins = 0
	private var uptodatePlugins = 0
	private var totalPlugins: Int { return updatedPlugins + uptodatePlugins }
	
	private lazy var statusItem: NSStatusItem = {
		let si = NSStatusBar.systemStatusBar().statusItemWithLength(25)
		
		if let button = si.button {
			let image = NSImage(named: "menuIcon")
			image?.template = true
			
			button.image = image
			button.imagePosition = Utils.displayTotalPlugins ? .ImageRight : .ImageOnly
		}
		
		return si
	}()
	
	private lazy var updateItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Update now", action: "updatePlugins", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		
		return mi
	}()
	
	private lazy var startAtLoginItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Start at login", action: "toggleStartAtLogin", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		mi.state = Utils.startAtLogin ? NSOnState : NSOffState
		
		return mi
	}()
	
	private lazy var displayTotalItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Show total plugins", action: "toggleDisplayTotal", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		mi.state = Utils.displayTotalPlugins ? NSOnState : NSOffState
		
		return mi
	}()
	
	private lazy var closeAfterUpdateMenu: NSMenu = {
		let m = NSMenu(title: "")
		m.autoenablesItems = false
		
		let closeItem     = NSMenuItem(title: "Activate", action: "activateCloseAfterUpdateMode", keyEquivalent: "")
		m.addItem(closeItem)
		closeItem.target  = self
		closeItem.enabled = true
		
		m.addItem(NSMenuItem.separatorItem())
		
		let descriptionItem     = NSMenuItem()
		m.addItem(descriptionItem)
		
		descriptionItem.enabled = false
		descriptionItem.attributedTitle = Utils.disabledMenuTitleWithString(
			"Turning this option on will enable the following behavior:\nwhen the app is launched, the plugins will update and the app\nwill automatically close. To turn off the option, keep\n⌥ (alt / option) or ⌘ (command) pressed while launching the app.",
			font: NSFont(name: self.font.fontName, size: self.font.pointSize - 4)!
		)
		
		return m
	}()
	
	private lazy var closeAfterUpdateMenuItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Close after updating", action: nil, keyEquivalent: "")
		mi.enabled = true
		mi.submenu = self.closeAfterUpdateMenu
		
		return mi
	}()
	
	
	// MARK: - UI
	
	private func updateUpdateItemTitle() {
		updateItem.title = "Update" + (Utils.displayTotalPlugins ? " (\(Utils.totalPlugins))" : "")
	}
	
	
	// MARK: - Actions
	
	@objc private func toggleStartAtLogin() {
		if Utils.startAtLogin {
			if SMLoginItemSetEnabled("com.rolandleth.PlugRocketHelper", false) {
				startAtLoginItem.state = NSOffState
				Utils.startAtLogin = false
			}
		}
		else {
			if SMLoginItemSetEnabled("com.rolandleth.PlugRocketHelper", true) {
				startAtLoginItem.state = NSOnState
				Utils.startAtLogin = true
			}
		}
		
		update()
	}
	
	@objc private func toggleDisplayTotal() {
		Utils.displayTotalPlugins = !Utils.displayTotalPlugins
		Utils.userDefaults.synchronize()
		
		displayTotalItem.state = Utils.displayTotalPlugins ? NSOnState : NSOffState
		updateUpdateItemTitle()
	}
	
	@objc private func quit() {
		NSApp.terminate(nil)
	}
	
	// Just for the button, because the sender gets fucked up with the completionBlock otherwise
	@objc private func updatePlugins() {
		updatePlugins({})
	}
	
	private func updatePlugins(completion: () -> Void = {}) {
		updateItem.enabled         = false
		updateItem.attributedTitle = Utils.disabledMenuTitleWithString("Updating...", font: self.font)
		update()
		
		let plugins = Utils.totalPlugins
		let genericErrorMessage = "Something went wrong."
		
		let finishUpdate = {
			self.updateItem.enabled         = true
			self.updateItem.attributedTitle = nil
			self.updateUpdateItemTitle()
			
			// Since we don't have a "Show total plugins" menu item
			// if there is no data about plugins yet, or there are 0 plugins,
			// the first time an update is done and plugins are found,
			// auto-turn on the option, so it's obvious what it does.
			if plugins == 0 && self.totalPlugins > 0 {
				Utils.displayTotalPlugins = true
				Utils.userDefaults.synchronize()
				
				self.updateUpdateItemTitle()
				self.displayTotalItem.state = NSOnState
			}
			
			if self.totalPlugins > 0 && self.displayTotalItem.menu == nil {
				self.insertItem(self.displayTotalItem, atIndex: 1)
			}
			
			self.update()
		}
		
		Sandbox.askForSandboxPermissionFor(.Plugins, success: {
			guard let xcodeUUID = Sandbox.runScriptFor(.Xcode) else {
				Utils.postNotificationWithText("Could not read Xcode's UUID.")
				return // This should never happen
			}
			
			if Utils.xcodeUUID != xcodeUUID {
				Utils.xcodeUUID = xcodeUUID.stringByReplacingOccurrencesOfString("\n",
					withString: ""
				)
				Utils.userDefaults.synchronize()
			}
			
			let manager = NSFileManager.defaultManager()
			guard
				let pluginURL = NSURL(string: Utils.pluginsURL),
				var plists = try? manager.contentsOfDirectoryAtURL(pluginURL,
					includingPropertiesForKeys: [],
					options: .SkipsHiddenFiles) else {
						Utils.postNotificationWithText(genericErrorMessage)
						return
			}
			
			plists = plists.map() { url in
				return url.URLByAppendingPathComponent("/Contents/Info.plist")
			}
			
			var updatedPlugins = 0
			var uptodatePlugins = 0
			for plist in plists {
				guard
					let plistDictionary = NSMutableDictionary(contentsOfURL: plist),
					var ids = plistDictionary["DVTPlugInCompatibilityUUIDs"] as? [String] else {
						Utils.postNotificationWithText(genericErrorMessage)
						return
				}
				
				guard !ids.contains(Utils.xcodeUUID) else { uptodatePlugins++; continue }
				
				updatedPlugins++
				ids.append(Utils.xcodeUUID)
				plistDictionary["DVTPlugInCompatibilityUUIDs"] = ids
				plistDictionary.writeToURL(plist, atomically: true)
			}
			
			self.postUpdateNotification([updatedPlugins, uptodatePlugins])
			finishUpdate()
			completion()
			
			return
		}) {
			finishUpdate()
			Utils.postNotificationWithText("You need to grant permission to the plug-ins folder.")
		}
	}
	
	private func postUpdateNotification(values: [Int]) {
		updatedPlugins = values.first!
		uptodatePlugins = values.last!
		
		let text: String
		
		switch (updatedPlugins, uptodatePlugins) {
		case (0, 1): text = "You have only one plugin, and it was already up to date."
		case (0, _): text = "All \(uptodatePlugins) plugins were already up-to-date."
		case (1, 0): text = "You have only one plugin, and it has been updated."
		case (_, 0): text = "All \(updatedPlugins) plugins were updated."
		case (1, 1): text = "1 plugin was updated, 1 plugin was already up-to-date."
		case (1, _): text = "1 plugin was updated, \(uptodatePlugins) plugins were already up-to-date."
		case (_, 1): text = "\(updatedPlugins) plugins were updated, 1 plugin was already up-to-date."
		default: text = "\(updatedPlugins) plugins were updated, \(uptodatePlugins) plugins were already up-to-date."
		}
		
		Utils.postNotificationWithText(text, success: true)
		Utils.totalPlugins = updatedPlugins + uptodatePlugins
		Utils.userDefaults.synchronize()
	}

	@objc private func activateCloseAfterUpdateMode() {
		Utils.closeAfterUpdate = true
		
		updatePlugins() {
			self.quit()
		}
	}
	
	
	// MARK: - Init
	
	init() {
		super.init(title: "")
		
		NSUserNotificationCenter
			.defaultUserNotificationCenter()
			.delegate = self
		
		autoenablesItems = false
		
		addItem(updateItem)
		if Utils.totalPlugins > 0 {
			addItem(displayTotalItem)
		}
		addItem(startAtLoginItem)
		addItem(closeAfterUpdateMenuItem)
		addItem(NSMenuItem.separatorItem())
		
		let quitItem = NSMenuItem(title: "Quit", action: "quit", keyEquivalent: "")
		quitItem.enabled = true
		quitItem.target = self
		addItem(quitItem)
		
		let modifierPressed = NSEvent.modifierFlags() == .AlternateKeyMask || NSEvent.modifierFlags() == .CommandKeyMask
		if Utils.closeAfterUpdate && !modifierPressed {
			updatePlugins() {
				self.quit()
			}
		}
		else {
			Utils.closeAfterUpdate = false
			
			statusItem.menu = self
			updateUpdateItemTitle() // To update the title
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
		return true
	}
}
