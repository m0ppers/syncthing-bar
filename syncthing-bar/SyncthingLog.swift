//
//  SyncthingLog.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 15.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Foundation

class SyncthingLog {
    var logBuffer : Array<String> = []
    
    func log(line: String) {
        logBuffer.append(line)
        if logBuffer.count >= 10000 {
            logBuffer.removeAtIndex(0)
        }
    }
}