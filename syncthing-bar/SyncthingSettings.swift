//
//  SyncthingSettings.swift
//  syncthing-bar
//
//  Created by Christoph Russ on 1/06/2015.
//  Copyright (c) 2015 CR. All rights reserved.
//

import Foundation
import Cocoa

class SyncthingSettings {
    
    var bw_icon_key: String = "BlackWhiteIcon"
    var bw_icon: Bool = true
    
    var invert_icon_key: String = "InvertIcon"
    var invert_icon: Bool = false
    
    var port_key: String = "PortNumber"
    var port: String = "8084"
    
    var confirm_exit_key: String = "ConfirmExit"
    var confirm_exit: Bool = true
    
    var monitoring_key: String = "Monitoring"
    var monitoring: Bool = false
    
    var monitor_apps_key: String = "MonitorApps"
    var monitor_apps = "iPhoto; iMovie\nLightroom"
    
    init() {
        self.bw_icon_key = "BlackWhiteIcon"
        self.invert_icon_key = "InvertIcon"
        self.port_key = "PortNumber"
        self.confirm_exit_key = "ConfirmExit"
        self.monitoring_key = "Monitoring"
        self.monitor_apps_key = "MonitorApps"
        
        self.bw_icon = true
        self.invert_icon = false
        self.port = "8084"
        self.confirm_exit = true
        self.monitoring = false
        self.monitor_apps = "iPhoto; iMovie,\niTunes, Lightroom"
        
        self.loadSettings()
    }
    
    init(bw_icon: Bool, invert_icon: Bool, port: String, confirm_exit: Bool, monitoring: Bool, monitor_apps: String) {
        self.bw_icon = bw_icon
        self.invert_icon = invert_icon
        self.port = port
        self.confirm_exit = confirm_exit
        self.monitoring = monitoring
        self.monitor_apps = monitor_apps
        
        self.saveSettings()
    }
    
    func loadSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let bw_icon = defaults.valueForKey(self.bw_icon_key) as? Bool {
            self.bw_icon = bw_icon
        }
        
        if let invert_icon = defaults.valueForKey(self.invert_icon_key) as? Bool {
            self.invert_icon = invert_icon
        }
        
        if let port_string = defaults.valueForKey(self.port_key) as? String {
            self.port = port_string
        }
        
        if let confirm_exit = defaults.valueForKey(self.confirm_exit_key) as? Bool {
            self.confirm_exit = confirm_exit
        }
        
        if let monitoring = defaults.valueForKey(self.monitoring_key) as? Bool {
            self.monitoring = monitoring
        }
        
        if let monitor_apps_string = defaults.valueForKey(self.monitor_apps_key) as? String {
            self.monitor_apps = monitor_apps_string
        }
    }
    
    func saveSettings() {
        // stored in preference folder
        // (e.g. ~/Library/Preferences/koeln.mop.syncthing-bar.plist)
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setValue(self.bw_icon, forKey: self.bw_icon_key)
        defaults.setValue(self.invert_icon, forKey: self.invert_icon_key)
        defaults.setValue(self.port, forKey: self.port_key)
        defaults.setValue(self.confirm_exit, forKey: self.confirm_exit_key)
        defaults.setValue(self.monitoring, forKey: self.monitoring_key)
        defaults.setValue(self.monitor_apps, forKey: self.monitor_apps_key)
        
        defaults.synchronize()
    }
    
    func applySettings(wndCtrl: SettingsWindowController) {
        if (self.bw_icon) {
            wndCtrl.bw_icon_check?.state = NSOnState
        } else {
            wndCtrl.bw_icon_check?.state = NSOffState
        }
        
        if (self.invert_icon) {
            wndCtrl.invert_icon_check?.state = NSOnState
        } else {
            wndCtrl.invert_icon_check?.state = NSOffState
        }
        
        wndCtrl.port_field?.stringValue = self.port as String
        
        if (self.confirm_exit) {
            wndCtrl.confirm_exit_check?.state = NSOnState
        } else {
            wndCtrl.confirm_exit_check?.state = NSOffState
        }
        
        if (self.monitoring) {
            wndCtrl.monitoring_check?.state = NSOnState
        } else {
            wndCtrl.monitoring_check?.state = NSOffState
        }
        
        wndCtrl.monitor_apps?.stringValue = self.monitor_apps as String
    }
}
