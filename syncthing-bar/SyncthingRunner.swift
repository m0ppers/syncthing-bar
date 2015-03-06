//
//  SyncthingRunner.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 13.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Foundation

let TooManyErrorsNotification = "koeln.mop.too-many-errors"
let HttpChanged = "koeln.mop.http-changed"
let FoldersDetermined = "koeln.mop.folders-determined"

class SyncthingRunner: NSObject {
    var portFinder : PortFinder = PortFinder(startPort: 8084)
    var path : NSString
    //var path : NSString = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"binaryname"]"/Users/mop/Downloads/syncthing-macosx-amd64-v0.10.8/syncthing"
    var task: NSTask?
    var port: NSInteger?
    var lastFail : NSDate?
    var failCount : NSInteger = 0
    var notificationCenter: NSNotificationCenter = NSNotificationCenter.defaultCenter()
    var portOpenTimer : NSTimer?
    var repositoryCollectorTimer : NSTimer?
    var log : SyncthingLog
    var buf : NSString = NSString()
    var apiKey: NSString?

    init(log: SyncthingLog) {
        self.log = log
        path = NSBundle.mainBundle().pathForResource("syncthing/syncthing", ofType: "")!
        
        super.init()
    
        notificationCenter.addObserver(self, selector: "taskStopped:", name: NSTaskDidTerminateNotification, object: task)
        notificationCenter.addObserver(self, selector: "receivedOut:", name: NSFileHandleDataAvailableNotification, object: nil)
    }
    
    func run() -> (String?) {
        var pipe : NSPipe = NSPipe()
        let readHandle = pipe.fileHandleForReading
        
        task = NSTask()
        task!.launchPath = path
        var environment = NSProcessInfo.processInfo().environment as [String: String]
        environment["STNORESTART"] =  "1"
        task!.environment = environment

        let port = self.port!
        let httpData : [String: String] = ["host": "127.0.0.1", "port": String(port)];
        
        self.apiKey = randomStringWithLength(32);
        
        task!.arguments = ["-no-browser", "-gui-address=127.0.0.1:\(port)", "-gui-apikey=\(self.apiKey!)"]
        task!.standardOutput = pipe
        readHandle.waitForDataInBackgroundAndNotify()
        task!.launch()
        
        
        // mop: wait until port is open :O
        portOpenTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "checkPortOpen:", userInfo: httpData, repeats: true)
        return nil
    }
    
    func receivedOut(notif : NSNotification) {
        // Unpack the FileHandle from the notification
        let fh:NSFileHandle = notif.object as NSFileHandle
        // Get the data from the FileHandle
        let data = fh.availableData
        // Only deal with the data if it actually exists
        if data.length > 1 {
            // Since we just got the notification from fh, we must tell it to notify us again when it gets more data
            fh.waitForDataInBackgroundAndNotify()
            // Convert the data into a string
            let string = buf + NSString(data: data, encoding: NSUTF8StringEncoding)!
            var lines = string.componentsSeparatedByString("\n")
            buf = lines.removeLast()
            for line in lines {
                log.log("OUT: \(line)")
            }
        }
    }
    
    func ensureRunning() -> (String?) {
        let result = portFinder.findPort()
        // mop: ITS GO :O ZOMG!!111
        if (result.err != nil) {
            return "Could not find a port!"
        }
        self.port = result.port
        let err = run()
        return err
    }
    
    // mop: copy paste :D http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift looks good to me
    func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            var length = UInt32 (letters.length)
            var rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    func createRequest(path: NSString) -> NSMutableURLRequest {
        var url = NSURL(string: "http://localhost:\(self.port!)\(path)")
        var request = NSMutableURLRequest(URL: url!)
        request.addValue(self.apiKey!, forHTTPHeaderField: "X-API-Key")
        return request
    }
    
    func collectRepositories(timer: NSTimer) {
        // mop: jaja copy paste...must fix somewhen
        if let info = timer.userInfo as? Dictionary<String,String> {
            let host = info["host"]
            let port = info["port"]
            
            let request = createRequest("/rest/config")
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                if (error == nil) {
                    var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    
                    // mop: WTF am i typing :S
                    let folders = jsonResult["Folders"] as? Array<AnyObject>
                    if folders != nil {
                        let folderStructArr = folders!.filter({(object: AnyObject) -> (Bool) in
                            let id = object["ID"] as? String
                            let path = object["Path"] as? String
                            
                            return id != nil && path != nil
                        }).map({(object: AnyObject) -> (SyncthingFolder) in
                            let id = object["ID"] as? String
                            let pathTemp = object["Path"] as? String
                            let path = pathTemp?.stringByExpandingTildeInPath
                                                        
                            return SyncthingFolder(id: id!, path: path!)
                        })
                        
                        let folderData = ["folders": folderStructArr]
                        self.notificationCenter.postNotificationName(FoldersDetermined, object: self, userInfo: folderData)
                    } else {
                        println("Failed to parse folders :(")
                    }
                } else {
                    println("Got error collecting repositories \(error)")
                }
            }
        }
    }
    
    func checkPortOpen(timer: NSTimer) {
        if (timer.valid) {
            if let info = timer.userInfo as? Dictionary<String,String> {
                let host = info["host"]
                let port = info["port"]
                let url = NSURL(string: "http://\(host!):\(port!)/rest/version")
                let request = createRequest("/rest/version")
                
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                    if (error == nil) {
                        var httpData = ["host": host!, "port": port!]
                        self.notificationCenter.postNotificationName(HttpChanged, object: self, userInfo: httpData)
                        if (self.portOpenTimer!.valid) {
                            self.portOpenTimer!.invalidate()
                        }
                        self.repositoryCollectorTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: "collectRepositories:", userInfo: info, repeats: true)
                        self.repositoryCollectorTimer!.fire()
                    }
                }
            }
        }
    }
    
    func taskStopped(sender: AnyObject) {
        let task = sender.object as NSTask
        if (task != self.task) {
            return
        }
        
        var httpData = []
        self.notificationCenter.postNotificationName(HttpChanged, object: self)
        
        stopTimers()
        
        var current = NSDate()
        // mop: retry 5 times :S
        if (lastFail != nil) {
            let timeDiff = current.timeIntervalSinceDate(lastFail!)
            if (timeDiff > 5) {
                failCount = 0
            } else if (failCount <= 5) {
                failCount++
            } else {
                notificationCenter.postNotificationName(TooManyErrorsNotification, object: self)
                println("Too many errors. Stopping")
                return
            }
        }
        lastFail = current
        run()
    }
    
    func stopTimers() {
        if (portOpenTimer!.valid) {
            portOpenTimer!.invalidate()
        }
        
        if (repositoryCollectorTimer != nil) {
            if (repositoryCollectorTimer!.valid) {
                repositoryCollectorTimer!.invalidate()
            }
        }
    }
    
    func stop() {
        if (task != nil) {
            task!.terminate();
        }
        stopTimers()
    }
}
