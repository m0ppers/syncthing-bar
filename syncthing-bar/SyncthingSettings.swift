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
    var bw_icon: Bool
    var invert_icon: Bool
    var port: String
    var confirm_exit: Bool
    
    init() {
        self.bw_icon = true
        self.invert_icon = false
        self.port = "8084"
        self.confirm_exit = true
    }
    
    init(bw_icon: Bool, invert_icon: Bool, port: String, confirm_exit: Bool) {
        self.bw_icon = bw_icon
        self.invert_icon = invert_icon
        self.port = port
        self.confirm_exit = confirm_exit
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
