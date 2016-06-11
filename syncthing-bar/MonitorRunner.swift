//
//  MonitorRunner.swift
//  syncthing-bar
//
//  Created by Christoph Russ on 3/06/2015.
//  Copyright (c) 2015 CR. All rights reserved.
//

import Foundation
import AppKit

class MonitorRunner: NSObject {
    var activated: Bool
    var timer_interval: Double
    var apps: [String]
    var monitorTimer : NSTimer?
    var notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    
    init(monitor_apps: String?) {
        self.activated = false
        self.timer_interval = 4.0
        self.apps = []
        
        super.init()
        
        self.set_apps(monitor_apps)
        //self.startMonitor()
    }
    
    func set_apps(monitor_apps: String?) {
        self.apps.removeAll()
        
        let separators = NSCharacterSet(charactersInString: ",;\n\t")
        let whitespaceNewLine = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let app_array = monitor_apps!.componentsSeparatedByCharactersInSet(separators)
        
        for app in app_array {
            if !app.isEmpty {
                let app_trim = app.stringByTrimmingCharactersInSet(whitespaceNewLine);
                self.apps.append(app_trim)
            }
        }
    }
    
    func startMonitor() {
        if (monitorTimer != nil && monitorTimer!.valid) {
            return
        }
        //print("Starting TIMER for app monitor.\n")
        let appData : [String: String] = ["":""];
        monitorTimer = NSTimer.scheduledTimerWithTimeInterval(self.timer_interval, target: self, selector: #selector(MonitorRunner.checkApps(_:)), userInfo: appData, repeats: true)
    }
    
    func stopMonitor() {
        //print("Stopping TIMER for app monitor.\n")
        if (monitorTimer != nil && monitorTimer!.valid) {
            monitorTimer!.invalidate()
        }
    }
    
    func checkApps(timer: NSTimer) {
        if (!timer.valid) {
            return
        }
        
        let running_apps: [String] = self.getRunningAppNames()
        
        for monitor_app in self.apps {
            if running_apps.contains(monitor_app) {
                let startStopData = ["pause": true]
                notificationCenter.postNotificationName(StartStop, object: self, userInfo: startStopData)
                self.activated = true
                return
            }
        }
        
        if self.activated {
            // it appears non of these apps are active any-longer - so we can continue ..
            self.activated = false
            let startStopData = ["pause": false]
            notificationCenter.postNotificationName(StartStop, object: self, userInfo: startStopData)
        }
        
    }
    
    func getRunningAppNames() -> [String] {
        let r_apps = NSWorkspace().runningApplications 
        var r_app_names: [String] = []
        
        for r_app in r_apps {
            let r_app_name: String = r_app.localizedName! //bundleIdentifier (e.g. com.apple.iTunes)
            r_app_names.append(r_app_name)
            
            // this would check for ANY appearance of the app name
            /*if r_app_name.rangeOfString(...) != nil{ }
            if contains(self.apps,r_app_name) {
                //println(r_app_name)
                return true
            }*/
        }
        
        return r_app_names
    }
}

