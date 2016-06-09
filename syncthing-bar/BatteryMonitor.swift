//
//  BatteryMonitor.swift
//  syncthing-bar
//
//  Created by Sascha Hagedorn on 09/06/16.
//  Copyright © 2016 mop. All rights reserved.
//

import Foundation

class BatteryMonitor: NSObject {
    var timer_interval: Double
    var monitorTimer : NSTimer?
    var notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    
    override init() {
        self.timer_interval = 4.0
        
        super.init()
    }
    
    func startMonitor() {
        if (monitorTimer != nil && monitorTimer!.valid) {
            return
        }
    
        monitorTimer = NSTimer.scheduledTimerWithTimeInterval(self.timer_interval,
                                                              target: self,
                                                              selector: #selector(BatteryMonitor.checkBattery(_:)),
                                                              userInfo: nil,
                                                              repeats: true)
    }
    
    func stopMonitor() {
        if (monitorTimer != nil && monitorTimer!.valid) {
            monitorTimer!.invalidate()
        }
    }
    
    func checkBattery(timer: NSTimer) {
        if (!timer.valid) {
            return
        }
        
        let startStopData = ["pause" : isOnBattery()]
        notificationCenter.postNotificationName(StartStop, object: self, userInfo: startStopData)
    }
    
    func isOnBattery() -> Bool {
        let timeRemaining: CFTimeInterval = IOPSGetTimeRemainingEstimate()
        
        if timeRemaining == -2.0 {
            return false
        }
        
        return true
    }
}
