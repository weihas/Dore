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
    @ObservedObject var progressViewModel: ProgressViewControl
    
    
    var gcdTimer: DispatchSourceTimer?
   
    
    init(_ statusItem :NSStatusItem , _ Menu :NSMenu , _ progressViewModel : ProgressViewControl) {
        self.statusItem = statusItem
        self.Menu = Menu
        self.progressViewModel = progressViewModel
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
        self.statusItem.button!.subviews.removeAll()
        
        if SettingItem.themeSetting {
            let BottonView1 = CapsuleProgress(ViewModel: progressViewModel).frame(width: 9 , height: 21, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView1)
            progressIndicator.frame = NSRect(x: 0, y: 0, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }else{
            let BottonView2 =  CircleView(ViewModel: progressViewModel).frame(width: 20 , height: 16, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView2)
            progressIndicator.frame = NSRect(x: 0, y: 1, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }
    }
    
    
    func Refresh() {
        let time = SettingItem.energySaving ? 1:1.5
        
        gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        gcdTimer?.setEventHandler(handler: {
            self.progressViewModel.refresh()
        })
        
        
        gcdTimer?.schedule(deadline: .now(), repeating: time , leeway: .seconds(1))
        //gcdTimer?.schedule(deadline: .now() + 1)
        gcdTimer?.resume()
    }
}
















extension StatusItemControl{
    @objc func mouseClickHandler(){
        let source = """
                        tell application "System Events"
                                tell appearance preferences
                                    set dark mode to not dark mode
                                end tell
                            end tell
                        """
        
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseUp:
                    Process.launchedProcess(launchPath: "/usr/bin/osascript", arguments: ["-e",source])
                    print("Hello1")
                break
            case .rightMouseUp:
                statusItem.menu = Menu
                statusItem.button?.performClick(nil)
                self.statusItem.menu = nil
                print("Hello2")
                break
            default:
            break
            }
        }
    }
}
