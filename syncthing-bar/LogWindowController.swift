//
//  SettingsWindowController.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 13.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Cocoa

class LogWindowController: NSWindowController {
    @IBOutlet var view: NSTextView!
    var log : SyncthingLog
    
    // mop: found in some blog...some workaround because windowNibName is not a designated init func
    override var windowNibName : String! {
        return "LogWindow"
    }
    
    init(log : SyncthingLog) {
        self.log = log
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Can't create from coder. I am too dumb and don't even know what it is.")
    }

    override func windowDidLoad() {
        // mop: mehhh...textview doesn't scale when resizing :S no idea yet...
        var joiner = "\n"
        view.insertText(joiner.join(log.logBuffer))
        super.windowDidLoad()
    }
}
