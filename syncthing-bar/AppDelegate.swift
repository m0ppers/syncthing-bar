//
//  AppDelegate.swift
//  syncthing-statusbar
//
//  Created by Andreas Streichardt on 12.12.14.
//  Copyright (c) 2014 Andreas Streichardt. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    //var settingsWindowController = SettingsWindowController() //windowNibName: "Settings")
    var runner : SyncthingRunner?
    var syncthingBar : SyncthingBar?
    var log : SyncthingLog = SyncthingLog()
    var monitor : MonitorRunner?
    var batteryMonitor : BatteryMonitor?
    
    func applicationWillFinishLaunching(aNotification: NSNotification?) {
        NSApp.setActivationPolicy(NSApplicationActivationPolicy.Accessory)
    }
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        syncthingBar = SyncthingBar(log: log)
        runner = SyncthingRunner(log: log)
        let result = runner!.ensureRunning()
        if (result != nil) {
            let alert = NSAlert()
            alert.addButtonWithTitle("Ok :(")
            alert.messageText = "Got a fatal error: \(result!) :( Exiting"
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            let response = alert.runModal()
            self.quit()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tooManyErrors:", name: TooManyErrorsNotification, object: runner)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "foldersDetermined:", name: FoldersDetermined, object: runner)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "httpChanged:", name: HttpChanged, object: runner)
        
        self.monitor = MonitorRunner(monitor_apps: syncthingBar?.settings?.monitor_apps)
        if self.syncthingBar!.settings!.monitoring {
            self.monitor?.startMonitor()
        }
        
        self.batteryMonitor = BatteryMonitor()
        if self.syncthingBar!.settings!.pause_on_battery {
            self.batteryMonitor?.startMonitor()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "settingsSet:", name: SettingsSet, object: syncthingBar?.setter)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startStop:", name: StartStop, object: syncthingBar)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startStop:", name: StartStop, object: monitor)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startStop:", name: StartStop, object: batteryMonitor)
    }
    
    func stop() {
        runner?.stop()
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // mop: i don't get it .... this will only get called when quitting via UI. SIGTERM will NOT land here and i fail installing a proper signal handler :|
        self.stop()
    }
        
    func settingsAction(sender : AnyObject) {
        //settingsWindowController.showWindow(sender)
    }
    
    func quitAction(sender : AnyObject) {
        if (syncthingBar!.settings!.confirm_exit) {
            let alert = NSAlert()
            alert.addButtonWithTitle("Yes")
            alert.addButtonWithTitle("Cancel")
            alert.messageText = "Are you sure you want to quit?"
            
            // FIX: THIS DOESN'T WORK ...
            //var remember_btn: NSButton = alert.addButtonWithTitle("Remember my decision.")
            //remember_btn.setButtonType(NSButtonType.OnOffButton)
            
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
        
            let response = alert.runModal()
            if (response != NSAlertFirstButtonReturn) {
                return
            }
        }
        self.quit()
    }
    
    func tooManyErrors(sender : AnyObject) {
        let alert = NSAlert()
        alert.addButtonWithTitle("Ok :(")
        alert.messageText = "Syncthing could not run. There were too many errors. Check log, and restart :("
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        
        let response = alert.runModal()
    }
    
    func genericError(errorMessage: String) {
        let alert = NSAlert()
        alert.addButtonWithTitle("Ok :(")
        alert.messageText = errorMessage
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        
        let response = alert.runModal()
    }
    
    func httpChanged(notification: NSNotification) {
        if let info = notification.userInfo {
            let host = notification.userInfo!["host"] as! NSString
            let port = notification.userInfo!["port"] as! NSString
            
            self.syncthingBar!.settings!.port = port as String
            
            syncthingBar!.enableUIOpener("http://\(host):\(port)")
        } else {
            syncthingBar!.disableUIOpener()
        }
    }
    
    func foldersDetermined(notification: NSNotification) {
        if let folders = notification.userInfo!["folders"] as? Array<SyncthingFolder> {
            syncthingBar!.setFolders(folders)
        }
    }
    
    func settingsSet(notification: NSNotification) {
        // ctp: maybe we should have a Settings class ...
        
        var settings = self.syncthingBar?.settings
        
        if let settings_ntfc = notification.userInfo!["settings"] as? SyncthingSettings {
            
            var valid_port : Bool = true
            let port_ntfc : String = settings_ntfc.port
            
            if ((port_ntfc.characters.count < 3) || (port_ntfc.characters.count > 5)) {
                valid_port = false
            }
            
            let portFromString = Int(port_ntfc)
            if ((portFromString) != nil) {
                if ((portFromString < 1000) || (portFromString > 65535)) {
                    valid_port = false
                }
            }
            else {
                valid_port = false
            }
            
            if (!valid_port) {
                self.genericError("You entered an invalid port number.")
                return
            }
            
            self.syncthingBar!.updateSettings(settings_ntfc)
            
        }
        
        //start stop app monitor from here ..?
        self.monitor!.set_apps(self.syncthingBar!.settings?.monitor_apps)
        
        if self.syncthingBar!.settings!.monitoring {
            self.monitor?.startMonitor()
        } else {
            self.monitor?.stopMonitor()
        }
        
        if self.syncthingBar!.settings!.pause_on_battery {
            self.batteryMonitor?.startMonitor()
        } else {
            self.batteryMonitor?.stopMonitor()
        }
    }
    
    func startStop(notification: NSNotification) {
        // ctp: pausing execution made possible :D
        
        if let pause_ntfc = notification.userInfo!["pause"] as? Bool {
            if pause_ntfc {
                self.runner?.pause()
            }
            else {
                self.runner?.play()
            }
        }
    }
    
    func quit() {
        NSApplication.sharedApplication().terminate(self)
    }

}
