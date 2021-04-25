//
//  BitSpeedRecord.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import Foundation
import SwiftUI

class StatusItemControl: ObservableObject{
    @Published var statusItem : NSStatusItem
    @Published var Menu: NSMenu
    var MaxSet :Double = 500*1024
    var MinSet :Double = 5*1024
    
    var time : Double {
        if UserDefaults.standard.bool(forKey: "energySaving") {
            return 1.5
        }else{
            return 1
        }
    }
    
    let ButtonViewModel = ButtonViewControl()
    
    var  theme : Bool = UserDefaults.standard.bool(forKey: "themeSetting")
    
    
    let source = """
                    tell application "System Events"
                            tell appearance preferences
                                set dark mode to not dark mode
                            end tell
                        end tell
                    """
    
    var gcdTimer: DispatchSourceTimer?
   
    
    init(_ statusItem :NSStatusItem , _ Menu :NSMenu) {
        self.statusItem = statusItem
        self.Menu = Menu
//        ConvertSet()
    }
    
    func creatStatusBarItem(){
        self.statusItem.button?.target = self
//        statusItem.button?.action = #selector(AppDelegate.itemAction(_:))
        self.statusItem.button?.action = #selector(mouseClickHandler)
        self.statusItem.button?.sendAction(on: [.leftMouseUp,.rightMouseUp])
        DrawStatusBarItem()
        Refresh()
    }
    
    func DrawStatusBarItem(){
        //        statusItem.button!.title = "hello"
        self.statusItem.button!.subviews.removeAll()
        
        if theme {
            let BottonView1 = MyProgress1(ViewModel: ButtonViewModel).frame(width: 9 , height: 21, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView1)
            progressIndicator.frame = NSRect(x: 0, y: 0, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }else{
            let BottonView2 =  MyProgress2(ViewModel: ButtonViewModel).frame(width: 20 , height: 15, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView2)
            progressIndicator.frame = NSRect(x: 0, y: 0, width: 23, height: 22)
            self.statusItem.button!.addSubview(progressIndicator)
        }
    }
    
    
    func Refresh() {
        gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        gcdTimer?.setEventHandler(handler: {
            
            self.seekBits()
            self.calculateSpeed()
        })
        
        
        gcdTimer?.schedule(deadline: .now(), repeating: self.time , leeway: .seconds(1))
        //gcdTimer?.schedule(deadline: .now() + 1)
        gcdTimer?.resume()
    }
    
    
    func seekBits(){
        let args = "netstat -bI en0"    //Terminal command
        if let rows = Shell(args)?.split(separator: "\n").map({ String($0) }),
           rows.count > 1
        {
            let headers = rows[0].splittedByWhitespace
            let values = rows[1].splittedByWhitespace
            if let raw = String.getValue(of: "ibytes", in: values, of: headers), let bytes = UInt64(raw) {
                BitsValue.nowdata = Double(bytes)
            }
        }
    }
    
    func calculateSpeed() {
        BitsValue.NowDelta = BitsValue.nowdata-BitsValue.lastdata
        BitsValue.lastdata = BitsValue.nowdata

        if BitsValue.lastdata == 0 {
            BitsValue.NowDelta = 0
        }
        
        if (BitsValue.NowDelta > MinSet || BitsValue.LastDelta > MinSet) && (BitsValue.NowDelta < MaxSet || BitsValue.LastDelta < MaxSet) && (BitsValue.LastDelta != BitsValue.NowDelta ) {
            self.ButtonViewModel.Refresh(minValue: 0, maxValue: MaxSet, NowValue: BitsValue.NowDelta/self.time)
        }
        
        
        BitsValue.LastDelta = BitsValue.NowDelta
    }
    
    
    
    
}
















extension StatusItemControl{

    @objc func mouseClickHandler(){
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseUp:
                print("Hello")
                Process.launchedProcess(launchPath: "/usr/bin/osascript", arguments: ["-e",source])
                break
            case .rightMouseUp:
                statusItem.menu = Menu
                statusItem.button?.performClick(nil)
                self.statusItem.menu = nil
                break
            default:
            break
            }
        }
    }
   
    
    func ConvertSet() {
        
        self.MaxSet = Double(Int(UserDefaults.standard.string(forKey: "maxSetting")!) ?? 500)
        self.MinSet = Double(Int(UserDefaults.standard.string(forKey: "minSetting")!) ?? 5)
        self.MaxSet = self.MaxSet * 1024
        self.MinSet = self.MinSet * 1024
        if UserDefaults.standard.bool(forKey: "maxUnit") {
            self.MaxSet = self.MaxSet * 1024
        }
        if UserDefaults.standard.bool(forKey: "minUnit") {
            self.MinSet = self.MinSet * 1024
        }
    }
    
    
    
    
    
    
    
    enum speedUnit {
        case B
        case KB
        case MB
        case GB
    }
    
    
    
    
    

    func Convert(_ Delta :Double) -> (Double,speedUnit) {
        var num :Double = Delta
        var unit = speedUnit.B
        var times = 0
        
        
        while num > 1024 {
            num = num/1024
            times += 1
        }
        switch times {
        case 0:
            unit = speedUnit.B
        case 1:
            unit = speedUnit.KB
        case 2:
            unit = speedUnit.MB
        case 3:
            unit = speedUnit.GB
        default:
            unit = speedUnit.B
        }
        return (num,unit)
        
    }
    
    
    
}
