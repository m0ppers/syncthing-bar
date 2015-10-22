//
//  SyncthingBarTests.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 23.06.15.
//  Copyright (c) 2015 mop. All rights reserved.
//

import Cocoa
import XCTest
import syncthing_bar

class DummyWorkspace: NSWorkspace {
    internal var openedUrl : NSURL?
    
    override func openURL(url: NSURL) -> Bool {
        self.openedUrl = url
        return true
    }
}

class SyncthingBarTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOpenWhitespacedFolder() {
        var log : SyncthingLog = SyncthingLog()
        let syncthingBar = SyncthingBar(log: log);
        
        var sender = NSMenuItem();
        sender.representedObject = SyncthingFolder(id: NSString(string: "1"), path: NSString(string: "/der hans"));
        
        let workspace = DummyWorkspace()
        syncthingBar.workspace = workspace
        syncthingBar.openFolderAction(sender)
        XCTAssertEqual(workspace.openedUrl!.absoluteString, "file:///der%20hans")
    }
}
