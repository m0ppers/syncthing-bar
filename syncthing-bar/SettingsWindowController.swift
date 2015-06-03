//
//  SettingsWindowController.swift
//  syncthing-bar
//
//  Created by Christoph Russ on 1/06/2015.
//  Copyright (c) 2015 CR. All rights reserved.
//

import Cocoa

class SettingsWindowController: NSWindowController {
    @IBOutlet var bw_icon_check: NSButton!
    @IBOutlet var invert_icon_check: NSButton!
    @IBOutlet var port_field: NSTextField!
    @IBOutlet var confirm_exit_check: NSButton!
    @IBOutlet var monitoring_check: NSButton!
    @IBOutlet var monitor_apps: NSTextField!
    
    var settings: SyncthingSettings = SyncthingSettings()
    
    var notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    
    // mop: found in some blog...some workaround because windowNibName is not a designated init func
    override var windowNibName : String! {
        return "SettingsWindow"
    }
    
    init(settings: SyncthingSettings) {
        
        self.settings = settings //SyncthingSettings(bw_icon: bw_icon, invert_icon: invert_icon, port: port, confirm_exit: confirm_exit)
        
        super.init(window: nil)
        //super.init(windowNibName: "SettingsWindow")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Can't create from coder. I am too dumb and don't even know what it is.")
    }
    
    override func windowDidLoad() {
        //var joiner = "\n"
        //view.insertText(joiner.join(log.logBuffer))
        self.applySettings()
        super.windowDidLoad()
    }
    
    func applySettings() {
        
        settings.applySettings(self)
    }
    
    //settings actions
    
    @IBAction func bw_icon_checked(sender: NSButton) {
        self.settings.bw_icon = (sender.state == NSOnState)
        
        // FIX: this doesn't work - don't know how to fix right now
        /*if (bw_icon) {
            invert_icon_check.enabled = false
        } else {
            invert_icon_check.enabled = true
        }*/
        
        postSettings()
    }
    
    @IBAction func invert_icon_checked(sender: NSButton) {
        self.settings.invert_icon = (sender.state == NSOnState)
        
        postSettings()
    }
    
    @IBAction func port_changed(sender: NSTextField) {
        self.settings.port = sender.stringValue
        
        postSettings()
    }
    
    @IBAction func confirm_exit_checked(sender: NSButton) {
        self.settings.confirm_exit = (sender.state == NSOnState)
        
        postSettings()
    }
    
    @IBAction func monitoring_checked(sender: NSButton) {
        self.settings.monitoring = (sender.state == NSOnState)
        
        postSettings()
    }
    
    @IBAction func monitor_apps_changed(sender: NSTextField) {
        self.settings.monitor_apps = sender.stringValue
        
        postSettings()
    }
    
    func postSettings() {
        let settingsData = ["settings": self.settings]
        self.notificationCenter.postNotificationName(SettingsSet, object: self, userInfo: settingsData)
    }
}
