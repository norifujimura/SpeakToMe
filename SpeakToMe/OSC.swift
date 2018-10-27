//
//  OSC.swift
//  SpeakToMe
//
//  Created by Noriyuki Fujimura on 2018/10/28.
//  Copyright © 2018 Henry Mason. All rights reserved.
//

import Foundation


import SwiftOSC

class OSC {
    // Setup Client. Change address from localhost if needed.
    var client = OSCClient(address: "192.168.86.32", port: 8080)
    var address = OSCAddressPattern("/")
    func send(){
        var message = OSCMessage(
            OSCAddressPattern("/"),
            "Hello World"
        )
        client.send(message);
    }
    
}
