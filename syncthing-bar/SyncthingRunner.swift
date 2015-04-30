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
    var version: [Int]?

    init(log: SyncthingLog) {
        self.log = log
        path = NSBundle.mainBundle().pathForResource("syncthing/syncthing", ofType: "")!
        
        super.init()
    
        notificationCenter.addObserver(self, selector: "taskStopped:", name: NSTaskDidTerminateNotification, object: task)
        notificationCenter.addObserver(self, selector: "receivedOut:", name: NSFileHandleDataAvailableNotification, object: nil)
    }
    
    func registerVersion() -> Bool {
        var pipe : NSPipe = NSPipe()
        var versionTask = NSTask()
        versionTask.launchPath = path as String
        versionTask.arguments = ["--version"]
        versionTask.standardOutput = pipe
        versionTask.launch()
        versionTask.waitUntilExit()
        
        let versionOut = pipe.fileHandleForReading.readDataToEndOfFile()
        let versionString = NSString(data: versionOut, encoding: NSUTF8StringEncoding)
        
        var regex = NSRegularExpression(pattern: "^syncthing v(\\d+)\\.(\\d+)\\.(\\d+)",
            options: nil, error: nil)
        var results = regex!.matchesInString(versionString! as String, options: nil, range: NSMakeRange(0, versionString!.length))
        if results.count == 1 {
            let major = versionString?.substringWithRange(results[0].rangeAtIndex(1)).toInt() as Int!
            let minor = versionString?.substringWithRange(results[0].rangeAtIndex(2)).toInt() as Int!
            let patch = versionString?.substringWithRange(results[0].rangeAtIndex(3)).toInt() as Int!
            
            version = [ major, minor, patch ]
            println("Syncthing version \(version![0]) \(version![1]) \(version![2])")
            return true
        } else {
            return false
        }
    }
    
    func run() -> (String?) {
        var pipe : NSPipe = NSPipe()
        let readHandle = pipe.fileHandleForReading
        
        task = NSTask()
        task!.launchPath = path as String
        var environment = NSProcessInfo.processInfo().environment as! [String: String]
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
        let fh:NSFileHandle = notif.object as! NSFileHandle
        // Get the data from the FileHandle
        let data = fh.availableData
        // Only deal with the data if it actually exists
        if data.length > 1 {
            // Since we just got the notification from fh, we must tell it to notify us again when it gets more data
            fh.waitForDataInBackgroundAndNotify()
            // Convert the data into a string
            let string = (buf as String) + (NSString(data: data, encoding: NSUTF8StringEncoding)! as String)
            var lines = string.componentsSeparatedByString("\n")
            buf = lines.removeLast()
            for line in lines {
                log.log("OUT: \(line)")
            }
        }
    }
    
    func ensureRunning() -> (String?) {
        if !registerVersion() {
            return "Could not determine syncthing version"
        }
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
        request.addValue(self.apiKey! as String, forHTTPHeaderField: "X-API-Key")
        return request
    }
    
    func collectRepositories(timer: NSTimer) {
        // mop: jaja copy paste...must fix somewhen
        if let info = timer.userInfo as? Dictionary<String,String> {
            let host = info["host"]
            let port = info["port"]
            
            var request: NSMutableURLRequest
            var idElement: NSString
            var pathElement: NSString
            var foldersElement: NSString
            if version![0] == 0 && version![1] == 10 {
                request = createRequest("/rest/config")
                idElement = "Id"
                pathElement = "Path"
                foldersElement = "Folders"
            } else {
                request = createRequest("/rest/system/config")
                idElement = "id"
                pathElement = "path"
                foldersElement = "folders"
            }
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
                if (error != nil) {
                    println("Got error collecting repositories \(error)")
                    return;
                }
                let httpResponse = response as? NSHTTPURLResponse;
                if httpResponse == nil {
                    println("Unexpected response");
                    return;
                }
                
                if httpResponse!.statusCode != 200 {
                    println("Got non 200 HTTP Response \(httpResponse!.statusCode)");
                    return;
                }
                if (error == nil) {
                    var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                    
                    // mop: WTF am i typing :S
                    let folders = jsonResult[foldersElement] as? Array<AnyObject>
                    if folders != nil {
                        let folderStructArr = folders!.filter({(object: AnyObject) -> (Bool) in
                            let id = object[idElement] as? String
                            let path = object[pathElement] as? String
                            
                            return id != nil && path != nil
                        }).map({(object: AnyObject) -> (SyncthingFolder) in
                            let id = object[idElement] as? String
                            let pathTemp = object[pathElement] as? String
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
        let task = sender.object as! NSTask
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
        if (portOpenTimer != nil && portOpenTimer!.valid) {
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
