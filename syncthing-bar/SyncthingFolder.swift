//
//  SyncthingFolder.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 14.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Foundation

public class SyncthingFolder {
    var id: NSString
    var label: NSString
    var path: NSString
    
    public init(id: NSString, path: NSString) {
        self.id = id
        self.path = path
        self.label = ""
    }
    
    public convenience init(id: NSString, path: NSString, label: NSString) {
        self.init(id: id, path: path)
        self.label = label
    }
}