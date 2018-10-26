//
//  DrawView.swift
//  SpeakToMe
//
//  Created by Noriyuki Fujimura on 2018/10/26.
//  Copyright © 2018 Henry Mason. All rights reserved.
//

import Foundation
import UIKit

class DrawView: UIView {
    
    var cOne:UIColor=UIColor.gray;
    var cTwo:UIColor=UIColor.gray;
    var cThree:UIColor=UIColor.gray;
    
    func setColor(c:UIColor){
        self.cOne=c;
    }
    
    func setColor(cOne:UIColor,cTwo:UIColor){
        self.cOne=cOne;
        self.cTwo=cTwo;
    }
    
    override func draw(_ rect: CGRect) {
        
        let r=rect.height/2;
        
        let ovalOne = UIBezierPath(ovalIn: CGRect(x: rect.width/2-r, y: 0, width: rect.height, height: rect.height))
        // 塗りつぶし色の設定
        cOne.setFill()
        // 内側の塗りつぶし
        ovalOne.fill()
        
        let ovalTwoLeft = UIBezierPath(ovalIn: CGRect(x: rect.width/4-r, y: 0, width: rect.height, height: rect.height))
        let ovalTwoRight = UIBezierPath(ovalIn: CGRect(x: rect.width/4*3-r, y: 0, width: rect.height, height: rect.height))
        // 塗りつぶし色の設定
        cTwo.setFill();
        // 内側の塗りつぶし
        ovalTwoLeft.fill();
        ovalTwoRight.fill();
        
    }
}
