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
    var client:OSCClient;
    
    init(){
        client = OSCClient(address: "192.168.86.32", port: 8080)
    }
    
    init(port:Int){
        client = OSCClient(address: "192.168.86.32", port: port)
    }
    
    init(address:String,port:Int){
        client = OSCClient(address:address, port: port)
    }
    
    func sendRGB(r:Int,g:Int,b:Int){
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            r,g,b
        )
        client.send(message);
    }
    
    func sendRGB(r:[Int],g:[Int],b:[Int]){
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            r[0],g[0],b[0],
            r[1],g[1],b[1]
        )
        client.send(message);
    }
    
    func sendRGB(color:UIColor){
        let rgb=getRGBfromColor(color:color);
        
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            rgb.r,rgb.g,rgb.b
        )
        client.send(message);
        print("sendRGB sent");
    }
    

    func sendHSB(color:UIColor){
        let hsb=getHSBfromColor(color:color);
        
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            hsb.h,hsb.s,hsb.b
        )
        client.send(message);
        print("sendHSB sent");
    }
    
    func send(color:UIColor){
        let rgb=getRGBfromColor(color:color);
        let hsb=getHSBfromColor(color:color);
        
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            rgb.r,rgb.g,rgb.b,
            hsb.h,hsb.s,hsb.b
        )
        client.send(message);
    }
    
    /*
    func sendHSB(color:[UIColor]){
        var hsb=[getHSBfromColor(color:color[0]),getHSBfromColor(color:color[1])];
        let message = OSCMessage(
            OSCAddressPattern("/value"),
            hsb[0].h,hsb[0].s,hsb[0].b,
            hsb[1].h,hsb[1].s,hsb[1].b
        )
        client.send(message);
    }
 */
    
    func getHSBfromColor(color:UIColor)->(h:Int,s:Int,b:Int){
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a);
        return (Int(h*360),Int(s*100),Int(b*100));
    }
    
    func getRGBfromColor(color:UIColor)->(r:Int,g:Int,b:Int){
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a);
        return (Int(r*255),Int(g*255),Int(b*255));
    }
    
}
