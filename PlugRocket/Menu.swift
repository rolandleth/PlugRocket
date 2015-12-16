//
//  Menu.swift
//  PlugRocket
//
//  Created by Roland Leth on 14/12/15.
//  Copyright © 2015 Roland Leth. All rights reserved.
//

import Cocoa

class Menu: NSMenu {

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
	
	private lazy var pluginCountItem: NSMenuItem = {
		let mi     = NSMenuItem()
		mi.enabled = false
		mi.hidden = true
		
		return mi
	}()
	
	private lazy var updateItem: NSMenuItem = {
		let mi     = NSMenuItem(title: "Update now", action: "updatePlugins", keyEquivalent: "")
		mi.target  = self
		mi.enabled = true
		
		return mi
	}()
	
	private lazy var checkRegularlyItem: NSMenuItem = {
		let mi     = NSMenuItem()
		mi.action  = "toggleCheckRegularly"
		mi.target  = self
		mi.enabled = true
		
		return mi
	}()
	
	private lazy var displayTotalItem: NSMenuItem = {
		let mi     = NSMenuItem()
		mi.action  = "toggleDisplayTotal"
		mi.target  = self
		mi.enabled = true
		
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
			"Turning this option on will enable the following behavior:\nwhen the app is launched, the plugins will update and the app\nwill automatically close. To turn off the option,\nkeep ⌥ (alt / option) pressed while launching the app.",
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
	
	private lazy var checkRegularlyTimer: NSTimer = self._checkRegularlyTimer
	private var _checkRegularlyTimer: NSTimer {
		return NSTimer.scheduledTimerWithTimeInterval(24 * 3600,
			target: self,
			selector: "updatePlugins",
			userInfo: nil,
			repeats: true
		)
	}
	
	
	// MARK: - UI
	
	@objc private func darkModeChanged() {
		pluginCountItem.attributedTitle = Utils.disabledMenuTitleWithString("All plugins are up-to-date", font: self.font)
	}
	
	private func updateUpdateItemTitle() {
		updateItem.title = "Update" + (Utils.displayTotalPlugins ? " (\(Utils.totalPlugins))" : "")
	}
	
	private func updateDisplayTotalItemTitle() {
		displayTotalItem.title = (Utils.displayTotalPlugins ? "Hide" : "Show") + " total plugins"
	}
	
	private func updateForRegularChecking() {
		// Timer needs to be recreated after invalidation.
		checkRegularlyTimer = _checkRegularlyTimer
		checkRegularlyTimer.fire()
		checkRegularlyItem.title = "Disable daily update"
		
		addInfoItems()
	}
	
	private func addInfoItems() {
		insertItem(NSMenuItem.separatorItem(), atIndex: 0)
		insertItem(pluginCountItem, atIndex: 0)
	}
	
	
	// MARK: - Actions
	
	@objc private func toggleCheckRegularly() {
		if Utils.checkRegularly {
			checkRegularlyTimer.invalidate()
			checkRegularlyItem.title = "Enable daily update"
			
			for _ in 0..<2 {
				removeItemAtIndex(0)
			}
		}
		else {
			// Also used in init, due to the required timer.
			updateForRegularChecking()
		}
		
		darkModeChanged()
		
		Utils.checkRegularly = !Utils.checkRegularly
		Utils.userDefaults.synchronize()
	}
	
	@objc private func toggleDisplayTotal() {
		Utils.displayTotalPlugins = !Utils.displayTotalPlugins
		Utils.userDefaults.synchronize()
		
		updateUpdateItemTitle()
		updateDisplayTotalItemTitle()
	}
	
	@objc private func quit() {
		NSApplication.sharedApplication().terminate(nil)
	}
	
	// Just for the button, because the sender gets fucked up with the completionBlock otherwise
	@objc func updatePlugins() {
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
			
			// Since we don't have a "Show total plugins" item if there is 
			// no data about plugins yet, or there are 0 plugins,
			// the first time an update is done and plugins are found,
			// auto-turn on the option, so it's obvious what it does.
			if plugins == 0 && self.totalPlugins > 0 {
				Utils.displayTotalPlugins = true
				Utils.userDefaults.synchronize()
				self.updateUpdateItemTitle()
				self.updateDisplayTotalItemTitle()
			}
			
			if self.totalPlugins > 0 && self.displayTotalItem.menu == nil {
				self.insertItem(self.displayTotalItem, atIndex: 1)
			}
			
			self.update()
		}
		
		Sandbox.askForSandboxPermissionFor(.Plugins, success: {
			let task = NSTask()
			task.launchPath = "/usr/bin/ruby"
			task.arguments = [
				NSBundle.mainBundle().pathForResource("the_script", ofType: "rb")!,
				Utils.cleanedPluginsURL
			]
			
			let pipe = NSPipe()
			task.standardOutput = pipe
			task.launch()
			
			let resultData = pipe.fileHandleForReading.readDataToEndOfFile()
			
			guard
				let resultString = String(data: resultData, encoding: NSUTF8StringEncoding)
				else {
					Utils.postNotificationWithText(genericErrorMessage)
					return
			}
			
			let values = resultString.componentsSeparatedByString(",").map() {
				return NSString(string: $0).integerValue
			}
			
			guard values.count == 2 else {
				if resultString.isEmpty {
					Utils.postNotificationWithText(genericErrorMessage)
				}
				else {
					Utils.postNotificationWithText(resultString.componentsSeparatedByString("\n").first!)
				}
				
				return
			}
			
			self.postUpdateNotification(values)
			finishUpdate()
			completion()
		}) {
			finishUpdate()
			Utils.postNotificationWithText("You need to grant permission to the plug-ins folder.")
		}
	}
	
	private func postUpdateNotification(values: [Int]) {
		updatedPlugins = values.first!
		uptodatePlugins = values.last!
		
		// More expressive than its guard counterpart.
		// guard !Utils.checkRegularly || updatedPlugins > 0 else { return }
		if Utils.checkRegularly && updatedPlugins == 0 { return }
		
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
		
		autoenablesItems = false
		
		NSDistributedNotificationCenter.defaultCenter().addObserver(self,
			selector: "darkModeChanged",
			name: "AppleInterfaceThemeChangedNotification",
			object: nil
		)
		
		addItem(updateItem)
//		addItem(checkRegularlyItem)
		if Utils.totalPlugins > 0 {
			addItem(displayTotalItem)
		}
		addItem(closeAfterUpdateMenuItem)
		updateDisplayTotalItemTitle()
		addItem(NSMenuItem.separatorItem())
		
		let quitItem = NSMenuItem(title: "Quit", action: "quit", keyEquivalent: "")
		quitItem.enabled = true
		quitItem.target = self
		addItem(quitItem)
		
		if Utils.checkRegularly {
			updateForRegularChecking()
		}
		else if Utils.closeAfterUpdate && NSEvent.modifierFlags() != .AlternateKeyMask {
			updatePlugins() {
				self.quit()
			}
		}
		else {
			Utils.closeAfterUpdate = false
			checkRegularlyItem.title = "Enable daily update"
			darkModeChanged() // To update the menu items
			
			statusItem.menu = self
			updateUpdateItemTitle() // To update the title
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
