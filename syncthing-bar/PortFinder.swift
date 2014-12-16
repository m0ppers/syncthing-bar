//
//  PortFinder.swift
//  syncthing-bar
//
//  Created by Andreas Streichardt on 13.12.14.
//  Copyright (c) 2014 mop. All rights reserved.
//

import Foundation

class PortFinder {
    var startPort: NSInteger
    
    init(startPort: NSInteger) {
        self.startPort = startPort
    }
    
    // https://github.com/glock45/swifter/blob/master/Common/Socket.swift
    func port_htons(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
    
    func findPort() -> (port: NSInteger, err: NSString?) {
        for i in 0...100 {
            // mop: ahhh so this is apple usability
            let socket = CFSocketCreate(nil, 0, 0, 0, 0, nil, nil)
            if (socket == nil) {
                return (0, "Could not create test socket")
            }
            let port = startPort + i
            
            var addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)), sin_family: sa_family_t(AF_INET),
                sin_port: port_htons(in_port_t(port)), sin_addr: in_addr(s_addr: inet_addr("127.0.0.1")), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            
            var result = withUnsafePointer(&addr) { (pointer: UnsafePointer<sockaddr_in>) -> (Bool) in
                let cfData = CFDataCreate(nil, UnsafePointer<UInt8>(pointer), sizeof(sockaddr_in))
                let error = CFSocketSetAddress(socket, cfData)

                // mop: ok ... X-Codes autocompletion crashes continously and the docs seem to be wrong
                // this is what i would expect here normally
                // return error == CFSocketError.kCFSocketSuccess
                // doesn't work...maybe i am just too dumb for swift
                if (error.rawValue == 0) {
                    CFSocketInvalidate(socket)
                    return true
                } else {
                    return false
                }
            }
            
            if (result) {
                return (port, nil)
            }
        }
        return (0, "Could not find an open port :S")
    }
}