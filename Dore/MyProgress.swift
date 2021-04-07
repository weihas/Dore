//
//  MyProgress.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/24.
//

import SwiftUI
import Cocoa
//if possible i will do

class MyProgress: NSView {
    
    var MinValue: Double = 0.0
    var MidValue: Double = 50.0
    var MaxValue: Double = 500.0

    
    let view = SetPadView()
    
    var theme:Bool = false
    
    let CapsuleX :CGFloat = 4.5
    let CapsuleY :CGFloat = 0.5
    let CapsuleWidth: CGFloat = 8
    let CapsuleHeight: CGFloat = 21
    
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSGraphicsContext.saveGraphicsState() //保存绘图状态
        
        if MidValue>MaxValue {
            MidValue = MaxValue
        }
        let high :CGFloat = (CapsuleHeight-CapsuleY)*CGFloat(MidValue/MaxValue)+CapsuleY
        
        
        
        
        let aRect = NSMakeRect(CapsuleX,CapsuleY,CapsuleWidth,CapsuleHeight)
        
        let CapsulePath = NSBezierPath()
        CapsulePath.lineCapStyle = .round
        CapsulePath.lineWidth = 0.5
        NSColor(calibratedWhite: 1, alpha: 0.25).set()
        CapsulePath.appendRoundedRect(aRect, xRadius: 4, yRadius: 4)
        CapsulePath.stroke()
        CapsulePath.fill()
        
        
        if theme {
            //渲染式
            let aGrandient = NSGradient(colorsAndLocations: (NSColor.systemBlue,0.0),(NSColor(calibratedWhite: 1, alpha: 0.25),high/CapsuleHeight),(NSColor(calibratedWhite: 1, alpha: 0.25),1))
            aGrandient?.draw(in: CapsulePath, angle: 90)
        }else{
            
            let ProgressPath = NSBezierPath()
            ProgressPath.lineCapStyle = .round
            ProgressPath.lineWidth = 0.1
            if high<=8{
                if (high>1) {
                    ProgressPath.move(to: NSMakePoint(CapsuleX+4-sqrt((8-high)*high), high))
                    ProgressPath.appendArc(withCenter: .init(x: CapsuleX+4, y: CapsuleY+4), radius: 4, startAngle:180+asin((4-high)/4) , endAngle: 360-asin((4-high)/4), clockwise: false)
                    ProgressPath.line(to: NSMakePoint(CapsuleX+4+sqrt((8-high)*high), high))
                    //                ProgressPath.close()
                    NSColor.systemBlue.setFill()
                    NSColor(calibratedWhite: 1, alpha: 0.25).setStroke()
                    ProgressPath.stroke()
                    
                    ProgressPath.fill()
                }
                
            }else {
                let ProgressPath = NSBezierPath()
                ProgressPath.lineCapStyle = .round
                NSColor.systemBlue.set()
                ProgressPath.lineWidth = 8
                ProgressPath.move(to: NSMakePoint(8.5, 4))
                ProgressPath.line(to: NSMakePoint(8.5, high-4))
                ProgressPath.stroke()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}
