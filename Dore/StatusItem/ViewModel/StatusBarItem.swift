//
//  BitSpeedRecord.swift
//  PadDesign
//
//  Created by WeIHa'S on 2021/4/17.
//

import Foundation
import SwiftUI

class StatusBarItem: ObservableObject{
    @Published private var model: BitsDate
    var statusItem : NSStatusItem!
    var menu: NSMenu!
    
    // MARK: -Access to the model
    var nowPersent: Double {
        return model.nowPrecent
    }
    
    var settings: SettingItems
    
    var gcdTimer: DispatchSourceTimer?
    
    init(settingItems: SettingItems) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.settings = settingItems
        self.model = BitsDate(maxBits: settingItems.maxBits, minBits: settingItems.minBits)
        
    }
    
    func creatStatusBarItem(){
        self.statusItem.button?.target = self
        self.statusItem.button?.action = #selector(mouseClickHandler)
        self.statusItem.button?.sendAction(on: [.leftMouseUp,.rightMouseUp])
        DrawStatusBarItem()
        setUpMenuForItem()
        refresh()
        
    }
    
    func DrawStatusBarItem(){
        self.statusItem.button!.subviews.removeAll()
        if !settings.themeSetting {
            let BottonView1 = CapsuleProgress(ViewModel: self).frame(width: 9 , height: 21, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView1)
            progressIndicator.frame = NSRect(x: 0, y: 0, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }else{
            let BottonView2 =  CircleView(ViewModel: self).frame(width: 20 , height: 16, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView2)
            progressIndicator.frame = NSRect(x: 0, y: 1, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }
    }
    
    
    func refresh() {
        let time = settings.energySaving ? 1:1.5
        
        gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        gcdTimer?.setEventHandler(handler: {
            self.model.calculateSpeed()
        })
        
        
        gcdTimer?.schedule(deadline: .now(), repeating: time , leeway: .seconds(1))
        //gcdTimer?.schedule(deadline: .now() + 1)
        gcdTimer?.resume()
    }
    
    func setUpMenuForItem() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings", action: #selector(showSettingView), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "About", action: #selector(about), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self
        self.menu = menu
    }
    
    
}



extension StatusBarItem{
    @objc func showSettingView() {
        // Create the SwiftUI view that provides the window contents.
        AppDelegate.openSettingPane()
    }
    
    @objc func quit(){
        NSApplication.shared.terminate(self)
    }
    
    
    
    @objc func about(){
        
    }
    
    
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
                statusItem.menu = menu
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
