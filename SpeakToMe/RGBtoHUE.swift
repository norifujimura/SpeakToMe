//
//  RGBtoHUE.swift
//  SpeakToMe
//
//  Created by Noriyuki Fujimura on 2018/10/25.
//  Copyright © 2018 Henry Mason. All rights reserved.
//

import Foundation

//https://medium.com/simple-swift-programming-tips/how-to-convert-rgb-to-hue-in-swift-1d25338cad28
class RGBtoHUE{
    func rgbToHue(rInt:Int,gInt:Int,bInt:Int) -> (h:Int, s:Int, b:Int){
        let r:Float=Float(rInt)/255.0;
        let g:Float=Float(gInt)/255.0;
        let b:Float=Float(bInt)/255.0;
        
        let minV:Float = Float(min(r, g, b))
        let maxV:Float = Float(max(r, g, b))
        let delta:Float = maxV - minV
        var hue:Float = 0
        if delta != 0 {
            if r == maxV {
                hue = (g - b) / delta
            }
            else if g == maxV {
                hue = 2 + (b - r) / delta
            }
            else {
                hue = 4 + (r - g) / delta
            }
            hue *= 60
            if hue < 0 {
                hue += 360
            }
        }
        let saturation = maxV == 0 ? 0 : (delta / maxV)
        let brightness = maxV
        return (h:Int(hue), s:Int(saturation*100), b:Int(brightness*100));
    }
}
