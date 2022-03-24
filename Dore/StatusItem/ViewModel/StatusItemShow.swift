//
//  StatusItemShow.swift
//  Dore
//
//  Created by WeIHa'S on 2022/1/7.
//

import SwiftUI
import Foundation

class StatusItemShow: ObservableObject {
    @Published private var model = BitsDate()
    
    lazy var statusItem: NSStatusItem = {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.target = self
        item.button?.action = #selector(mouseClickHandler)
        item.button?.sendAction(on: [.leftMouseUp,.rightMouseUp])
        return item
    }()
    
    lazy var tapMenu: NSMenu = {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings", action: #selector(showSettingView), keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "About", action: #selector(about), keyEquivalent: "A").target = self
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "Q").target = self
        return menu
    }()
    
    
    private lazy var timer: DispatchSourceTimer? = {
        let time = SettingItems.defaults.energySaving ? 1.5 : 1
        
        let gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        
        gcdTimer.setEventHandler {[weak self] in
            self?.freshModel()
        }
        
        gcdTimer.schedule(deadline: .now(), repeating: time, leeway: .seconds(1))
        return gcdTimer
    }()
    
    
    init() {}
    
    
    // MARK: -Access to the model
    
    var nowPersent: Double {
        return model.persent
    }
    
    var nowValue: (String, String) {
        let value = SpeedUnit.getUnit(val: model.nowDelta)
        return  (String(format: "%.2f", value.0), value.1.name)
    }
    
    
    // MARK: -Intents

    
    func drawStatusBarItem(){
        self.statusItem.button?.subviews.removeAll()
        
        if SettingItems.defaults.themeSettingisCircle {
            let BottonView2 =  CircleView(vm: self).frame(width: 20 , height: 16, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView2)
            progressIndicator.frame = NSRect(x: 0, y: 1, width: 22, height: 23)
            self.statusItem.button!.addSubview(progressIndicator)
        }else{
            let BottonView1 = CapsuleProgress(vm: self).frame(width: 22 , height: 20, alignment: .center)
            let progressIndicator = NSHostingView(rootView: BottonView1)
            progressIndicator.frame = NSRect(x: 0, y: 0, width: 22, height: 24)
            self.statusItem.button!.addSubview(progressIndicator)
        }
    }
    
    func freshModel(){
        DispatchQueue.main.async { [weak self] in
            self?.model.refreshData()
        }
    }
    
    func startTimer(){
        timer?.resume()
    }
}

extension StatusItemShow{
    
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
                statusItem.menu = self.tapMenu
                statusItem.button?.performClick(nil)
                statusItem.menu = nil
                print("Hello2")
                break
            default:
            break
            }
        }
    }
}
