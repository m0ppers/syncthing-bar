//
//  SyncthingBar.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 14.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Cocoa

let FolderTag = 1

public class SyncthingBar: NSObject {
    var statusBar: NSStatusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu : NSMenu = NSMenu()
    var openUIItem: NSMenuItem
    var startStopSyncthingItem: NSMenuItem
    var url: NSString?
    var controller: LogWindowController?
    var settings: SyncthingSettings?
    var setter: SettingsWindowController?
    var log : SyncthingLog
    public var workspace : NSWorkspace = NSWorkspace.sharedWorkspace()
    
    public init(log : SyncthingLog) {
        self.log = log
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        
        let size = NSSize(width: 18, height: 18)
        let icon = NSImage(named: "syncthing-bar")
        // mop: that is the preferred way but the image is currently not drawn as it has to be and i am not an artist :(
        icon?.template = true
        icon?.size = size
        statusBarItem.image = icon
        
        menu.autoenablesItems = false
        
        openUIItem = NSMenuItem()
        openUIItem.title = "Open UI"
        openUIItem.action = Selector("openUIAction:")
        openUIItem.enabled = false
        menu.addItem(openUIItem)
        
        startStopSyncthingItem = NSMenuItem()
        startStopSyncthingItem.title = "Stop Syncthing"
        startStopSyncthingItem.action = Selector("startStopSyncthingAction:")
        startStopSyncthingItem.enabled = false
        menu.addItem(startStopSyncthingItem)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        let openLogItem : NSMenuItem = NSMenuItem()
        openLogItem.title = "Show Log"
        openLogItem.action = Selector("openLogAction:")
        openLogItem.enabled = true
        menu.addItem(openLogItem)
        
        // this will automagically check, if there are already settings stored and load them ...
        settings = SyncthingSettings()
        
        let openSettingsItem : NSMenuItem = NSMenuItem()
        openSettingsItem.title = "Settings"
        openSettingsItem.action = Selector("openSettingsAction:")
        openSettingsItem.enabled = true
        menu.addItem(openSettingsItem)
        
        let quitItem : NSMenuItem = NSMenuItem()
        quitItem.title = "Quit"
        quitItem.action = Selector("quitAction:")
        quitItem.enabled = true
        menu.addItem(quitItem)
        
        super.init()
        // mop: todo: move the remaining actions as well
        openUIItem.target = self
        startStopSyncthingItem.target = self
        openLogItem.target = self
        openSettingsItem.target = self
        
        self.updateSettings(self.settings!)
    }
    
    func enableUIOpener(uiUrl: NSString) {
        url = uiUrl
        openUIItem.enabled = true
        startStopSyncthingItem.enabled = true
    }
    
    func disableUIOpener() {
        openUIItem.enabled = false
    }
    
    func setFolders(folders: Array<SyncthingFolder>) {
        // mop: should probably check if anything changed ... but first simple stupid :S
        var item = menu.itemWithTag(FolderTag)
        while (item != nil) {
            menu.removeItem(item!)
            item = menu.itemWithTag(FolderTag)
        }
        
        // mop: maybe findByTag instead of hardcoded number?
        let startInsertIndex = 3
        var folderCount = 0
        for folder in folders {
            let folderItem : NSMenuItem = NSMenuItem()
            folderItem.title = "Open \(folder.id) in Finder"
            folderItem.representedObject = folder
            folderItem.action = Selector("openFolderAction:")
            folderItem.enabled = true
            folderItem.tag = FolderTag
            folderItem.target = self
            menu.insertItem(folderItem, atIndex: startInsertIndex + folderCount++)
        }
        
        // mop: only add if there were folders (we already have a separator after "Open UI")
        if (folderCount > 0) {
            let lowerSeparator = NSMenuItem.separatorItem()
            // mop: well a bit hacky but we need to clear this one as well ;)
            lowerSeparator.tag = FolderTag
            menu.insertItem(lowerSeparator, atIndex: startInsertIndex + folderCount)
        }
    }
    
    func openUIAction(sender: AnyObject) {
        if (url != nil) {
            workspace.openURL(NSURL(string: url! as String)!)
        }
    }
    
    func startStopSyncthingAction(sender: AnyObject) {
        let notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        let title: String = (sender as! NSMenuItem).title
        if title.rangeOfString("Stop") != nil {
            (sender as! NSMenuItem).title = "Start Syncthing"
            let startStopData = ["pause": true]
            notificationCenter.postNotificationName(StartStop, object: self, userInfo: startStopData)
        }
        else {
            (sender as! NSMenuItem).title = "Stop Syncthing"
            let startStopData = ["pause": false]
            notificationCenter.postNotificationName(StartStop, object: self, userInfo: startStopData)
        }
    }
    
    public func openFolderAction(sender: AnyObject) {
        let folder = (sender as! NSMenuItem).representedObject as! SyncthingFolder
        workspace.openURL(NSURL(fileURLWithPath: folder.path as String))
    }
    
    func openLogAction(sender: AnyObject) {
        // mop: recreate even if it exists (not sure if i manually need to close and cleanup :S)
        // seems wrong to me but works (i want to view current log output :S)
        controller = LogWindowController(log: log)
        controller?.showWindow(self)
        //controller?.window?.makeMainWindow()
        controller?.window?.makeKeyAndOrderFront(self)
    }
    
    func openSettingsAction(sender: AnyObject) {
        // ctp: settins window only used for syncthing-bar, not syncthing itself, although we could also configure port here ...
        
        setter = SettingsWindowController(settings: self.settings!)
        setter?.showWindow(self)
        //setter?.window?.makeMainWindow()
        setter?.window?.makeKeyAndOrderFront(self)
    }
    
    func updateSettings(settings: SyncthingSettings) {
        // ctp: somewhat redundany to storing this in the settings controller already?
        // maybe we shouldn't create the settings window over and over ?
        
        // TODO: we are not storing these settings anywhere useful, yet
        // TODO: maybe create an app-settings-dir in the appropriate ~/Library location and write the settings into there?
        
        self.settings = settings
        
        let icon: NSImage?;
        let size = NSSize(width: 18, height: 18)
        
        if (self.settings!.bw_icon) {
            if (self.settings!.invert_icon) {
                icon = NSImage(named: "syncthing-bar-invert")
                icon?.template = true
                icon?.size = size
                statusBarItem.image = icon
            } else {
                icon = NSImage(named: "syncthing-bar")
                icon?.template = true
                icon?.size = size
                statusBarItem.image = icon
            }
        } else {
            icon = NSImage(named: "AppIcon")
            //icon?.setTemplate(true)
            icon?.size = size
            statusBarItem.image = icon
        }
        
        self.settings?.saveSettings()

    }
 
}