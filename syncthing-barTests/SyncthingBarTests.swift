//
//  SyncthingBarTests.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 23.06.15.
//  Copyright (c) 2015 mop. All rights reserved.
//

import Cocoa
import XCTest
@testable import syncthing_bar

class DummyWorkspace: NSWorkspace {
    internal var openedUrl : NSURL?
    
    override func openURL(url: NSURL) -> Bool {
        self.openedUrl = url
        return true
    }
}

class SyncthingBarTests: XCTestCase {
    func testOpenWhitespacedFolder() {
        let log : SyncthingLog = SyncthingLog()
        let syncthingBar = SyncthingBar(log: log);
        
        let sender = NSMenuItem();
        sender.representedObject = SyncthingFolder(id: NSString(string: "1"), path: NSString(string: "/der hans"), label: NSString(string: "testung"));
        
        let workspace = DummyWorkspace()
        syncthingBar.workspace = workspace
        syncthingBar.openFolderAction(sender)
        XCTAssertEqual(workspace.openedUrl!.absoluteString, "file:///der%20hans")
    }
}
