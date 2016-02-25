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
	
	private lazy var updateXcodeBetaItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Also update Xcode-beta", action: "toggleUpdateXcodeBeta", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		mi.state = Utils.updateXcodeBeta ? NSOnState : NSOffState
		
		return mi
	}()
	
	private lazy var displayTotalItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Show total plugins", action: "toggleDisplayTotal", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		mi.state = Utils.displayTotalPlugins ? NSOnState : NSOffState
		
		return mi
	}()
	
	private lazy var revertItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Revert changes from last update", action: nil, keyEquivalent: "")
		mi.enabled = true
		mi.submenu = self.revertMenu
		
		return mi
	}()
	
	private lazy var revertMenu: NSMenu = {
		let m = NSMenu(title: "Revert changes from last update")
		m.autoenablesItems = false
		
		let revertAllItem     = NSMenuItem(title: "All", action: "revertAllPlugins", keyEquivalent: "")
		m.addItem(revertAllItem)
		revertAllItem.target  = self
		revertAllItem.enabled = true
		
		let revertSomeItem     = NSMenuItem(title: "Select...", action: "revertSomePlugins", keyEquivalent: "")
		m.addItem(revertSomeItem)
		revertSomeItem.target  = self
		revertSomeItem.enabled = true
		
		return m
	}()
	
	private lazy var closeAfterUpdateItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Close after updating", action: nil, keyEquivalent: "")
		mi.enabled = true
		mi.submenu = self.closeAfterUpdateMenu
		
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
			"Turning this option on will close the app and enable the following behavior:\nwhen the app is launched, the plugins will be updated and\nthe app will automatically close. To turn off the option, keep\n⌥ (alt / option) or ⌘ (command) pressed while launching the app.",
			font: NSFont(name: self.font.fontName, size: self.font.pointSize - 4)!
		)
		
		return m
	}()
	
	
	// MARK: - UI
	
	private func updateUpdateItemTitle() {
		updateItem.title = "Update" + (Utils.displayTotalPlugins ? " (\(Utils.totalPlugins))" : "")
	}
	
	
	// MARK: - Toggles
	
	@objc private func activateCloseAfterUpdateMode() {
		Utils.closeAfterUpdate = true
		updatePlugins(thenQuit: true)
	}
	
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
	
	@objc private func toggleUpdateXcodeBeta() {
		Utils.updateXcodeBeta = !Utils.updateXcodeBeta
		updateXcodeBetaItem.state = Utils.updateXcodeBeta ? NSOnState : NSOffState
		
		update()
	}
	
	@objc private func toggleDisplayTotal() {
		Utils.displayTotalPlugins = !Utils.displayTotalPlugins
		
		displayTotalItem.state = Utils.displayTotalPlugins ? NSOnState : NSOffState
		updateUpdateItemTitle()
	}
	
	@objc private func quit() {
		NSApp.terminate(nil)
	}
	
	
	// MARK: - Reverting
	
	private func revertPlugins(plugins: [NSURL]?, xcode: Sandbox.XcodeType) {
//		Sandbox.askForSandboxPermissionFor(.Plugins, success: {
		let result = Sandbox.revertPlugins(
			plugins?.map() {
				return $0.URLByAppendingPathComponent("Contents/Info.plist")
			}, xcode: xcode
		)
		
		let forXcode: String = {
			if Utils.updateXcodeBeta {
				return " for \(xcode.rawValue)"
			}
			
			return ""
		}()
		
		if result.0 > 0 {
			if result.0 == 1 {
				Utils.postNotificationWithText("\(result.0) plug-in has been reverted\(forXcode).", success: true)
			}
			else {
				Utils.postNotificationWithText("\(result.0) plug-ins have been reverted\(forXcode).", success: true)
			}
		}
		else if result.success {
			Utils.postNotificationWithText("No plug-ins were updated with PlugRocket\(forXcode).", success: true)
		}
	}
	
	@objc private func revertAllPlugins() {
		revertPlugins(nil, xcode: .Production)
		
		if Utils.updateXcodeBeta {
			Utils.delay(2.0) {
				self.revertPlugins(nil, xcode: .Beta)
			}
		}
	}
	
	@objc private func revertSomePlugins() {
		NSApp.activateIgnoringOtherApps(true)
		Sandbox.openPanel.allowsMultipleSelection = true
		Sandbox.openPanel.canChooseFiles          = true
		Sandbox.openPanel.message                 = "Select plug-ins to revert"
		
		guard Sandbox.openPanel.runModal() == NSFileHandlingPanelOKButton else { return }
		
		revertPlugins(Sandbox.openPanel.URLs, xcode: .Production)
		
		if Utils.updateXcodeBeta {
			Utils.delay(2.0) {
				self.revertPlugins(Sandbox.openPanel.URLs, xcode: .Beta)
			}
		}
	}
	
	
	// MARK: - Updating
	
	@objc private func updatePlugins() {
		updatePlugins(thenQuit: false)
	}
	
	private func updatePlugins(thenQuit quit: Bool) { // No default value, so it has a different signature than the above one
		updatePluginsFor(.Production) { [unowned self] in
			if Utils.updateXcodeBeta {
				Utils.delay(2.0) {
					self.updatePluginsFor(.Beta) {
						if quit { self.quit() }
					}
				}
			}
			else {
				if quit { self.quit() }
			}
		}
	}
	
	private func updatePluginsFor(xcode: Sandbox.XcodeType, completion: () -> Void) {
		guard Utils.disclaimerShown else {
			Utils.showDisclaimer { self.updatePlugins() }
			return
		}
		
		updateItem.enabled         = false
		updateItem.attributedTitle = Utils.disabledMenuTitleWithString("Updating...", font: self.font)
		update()
		
		let totalPlugins = Utils.totalPlugins
		
		let finishUpdate = {
			self.updateItem.enabled         = true
			self.updateItem.attributedTitle = nil
			self.updateUpdateItemTitle()
			
			// Since we don't have a "Show total plugins" menu item
			// if there is no data about plugins yet, or there are 0 plugins,
			// the first time an update is done and plugins are found,
			// auto-turn on the option, so it's obvious what it does.
			if totalPlugins == 0 && Utils.totalPlugins > 0 {
				Utils.displayTotalPlugins = true
				
				self.updateUpdateItemTitle()
				self.displayTotalItem.state = NSOnState
			}
			
			if Utils.totalPlugins > 0 && self.displayTotalItem.menu == nil {
				self.insertItem(self.displayTotalItem, atIndex: 1)
			}
			
			self.update()
		}
		
//		Sandbox.askForSandboxPermissionFor(.Plugins, success: {
		guard
			let xcodeUUID = Sandbox.runXcodeScriptFor(xcode)?
				.stringByReplacingOccurrencesOfString("\n", withString: "")
			where !xcodeUUID.isEmpty else {
				Utils.postNotificationWithText("Could not read Xcode\(xcode == .Beta ? "-beta" : "")'s UUID.") // blrgh
				return // This should never happen
		}
		
		if xcode == .Production {
			if Utils.xcodeUUID != xcodeUUID {
				Utils.xcodeUUID = xcodeUUID
				Utils.updatedPlugins = [String]()
			}
		}
		else {
			if Utils.xcodeBetaUUID != xcodeUUID {
				Utils.xcodeBetaUUID = xcodeUUID
				Utils.updatedBetaPlugins = [String]()
			}
		}
		
		self.postUpdateNotification(xcode: xcode, result: Sandbox.updatePlugins(xcode: xcode))
		finishUpdate()
		completion()
		
		return
	}
	
	private func postUpdateNotification(xcode xcode: Sandbox.XcodeType, result: (Int, Int, success: Bool)) {
		// If success is false, we already posted a notification.
		guard result.success else { return }
		
		updatedPlugins = result.0
		uptodatePlugins = result.1
		
		let withXcode: String = {
			if Utils.updateXcodeBeta {
				return " with \(xcode.rawValue)"
			}
			
			return ""
		}()
		
		let text: String = {
			switch (updatedPlugins, uptodatePlugins) {
			case (0, 0): return "You have no plugins."
			case (0, 1): return "You have only one plugin, and it was already up to date\(withXcode)."
			case (1, 0): return "You have only one plugin\(withXcode), and it has been updated."
			case (1, 1): return "1 plugin was updated\(withXcode), 1 plugin was already up-to-date."
			case (0, _): return "All \(uptodatePlugins) plugins were already up-to-date\(withXcode)."
			case (1, _): return "1 plugin was updated\(withXcode), \(uptodatePlugins) plugins were already up-to-date."
			case (_, 0): return "All \(updatedPlugins) plugins were updated\(withXcode)."
			case (_, 1): return "\(updatedPlugins) plugins were updated\(withXcode), 1 plugin was already up-to-date."
			case (_, _): return "\(updatedPlugins) plugins were updated\(withXcode), \(uptodatePlugins) plugins were already up-to-date."
			}
		}()
		
		Utils.postNotificationWithText(text, success: true)
		Utils.totalPlugins = updatedPlugins + uptodatePlugins
	}
	
	
	// MARK: - Init
	
	init() {
		super.init(title: "")
		
		NSUserNotificationCenter
			.defaultUserNotificationCenter()
			.delegate = self
		
		autoenablesItems = false
		
		addItem(updateItem)
		addItem(NSMenuItem.separatorItem())
		if Utils.totalPlugins > 0 {
			addItem(displayTotalItem)
		}
		addItem(startAtLoginItem)
		addItem(updateXcodeBetaItem)
		addItem(NSMenuItem.separatorItem())
		addItem(revertItem)
		addItem(closeAfterUpdateItem)
		
		let quitItem = NSMenuItem(title: "Quit", action: "quit", keyEquivalent: "")
		quitItem.enabled = true
		quitItem.target = self
		addItem(quitItem)
		
		let modifierPressed = NSEvent.modifierFlags() == .AlternateKeyMask || NSEvent.modifierFlags() == .CommandKeyMask
		if Utils.closeAfterUpdate && !modifierPressed {
			updatePlugins(thenQuit: true)
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
