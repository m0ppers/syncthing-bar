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
    
    init() {
        self.bw_icon_key = "BlackWhiteIcon"
        self.invert_icon_key = "InvertIcon"
        self.port_key = "PortNumber"
        self.confirm_exit_key = "ConfirmExit"
        
        self.bw_icon = true
        self.invert_icon = false
        self.port = "8084"
        self.confirm_exit = true
        
        self.loadSettings()
    }
    
    init(bw_icon: Bool, invert_icon: Bool, port: String, confirm_exit: Bool) {
        self.bw_icon = bw_icon
        self.invert_icon = invert_icon
        self.port = port
        self.confirm_exit = confirm_exit
        
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
            port = port_string
        }
        
        if let confirm_exit = defaults.valueForKey(self.confirm_exit_key) as? Bool {
            self.confirm_exit = confirm_exit
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
    }
}
