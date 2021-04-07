//
//  AppDelegate.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/24.
//

import Cocoa
import SwiftUI
import ServiceManagement
import NetworkExtension

@main
class AppDelegate: NSObject, NSApplicationDelegate{

    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var window: NSWindow!

    @IBOutlet weak var Menu: NSMenu!
    
//    let source = """
//                tell application "System Events"
//                        tell appearance preferences
//                            set dark mode to not dark mode
//                        end tell
//                    end tell
//                """

    
    @objc func mouseClickHandler(){
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseUp:
//                Process.launchedProcess(launchPath: "/usr/bin/osascript", arguments: ["-e",source])
                break
            case .rightMouseUp:
                statusItem.menu = Menu
                statusItem.button?.performClick(nil)
                break
            default:
            break
            }
        }
    }
    
    @IBAction func Quit(_sender: Any){
        NSApplication.shared.terminate(self)
    }
    
    
    @IBAction func Settings(_ sender: Any) {
        
    }
    
    var theme = true
    
    
    
    @IBAction func ShowSettingView(_ sender: Any) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = SetPadView()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView,.texturedBackground],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.isRestorable = false
        window.title = "Dore"
        window.setFrameAutosaveName("Dore Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    
    
    
    
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        createButtonStatusBar()
        Menu.delegate = self
    }
    

    

    
    
     func createButtonStatusBar() {
        if let button = statusItem.button {
            button.action = #selector(mouseClickHandler)
            button.sendAction(on: [.leftMouseUp,.rightMouseUp])
        }
        freshButton()
        Refresh()
    }
    
    var gcdTimer: DispatchSourceTimer?
    
    func Refresh() {
        gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        gcdTimer?.setEventHandler(handler: {
//            print("timeout")
            let args = "netstat -bI en0"
            if
                let rows = Shell(args)?.split(separator: "\n").map({ String($0) }),
                rows.count > 1
            {
                let headers = rows[0].splittedByWhitespace
                let values = rows[1].splittedByWhitespace
                if let raw = String.getValue(of: "ibytes", in: values, of: headers), let bytes = UInt64(raw) {
                    Bitspeed.nowdata = Double(bytes)
                }
            }
            Bitspeed.NowDelta = (Bitspeed.nowdata - Bitspeed.lastdata)/1536
            if Bitspeed.lastdata == 0{
                Bitspeed.NowDelta = 0
            }
            if (!((Bitspeed.LastDelta > 490 && Bitspeed.NowDelta > 490)||(Bitspeed.LastDelta < 5 && Bitspeed.NowDelta < 5)||(Bitspeed.LastDelta == Bitspeed.NowDelta))){
                self.freshButton()
            }
            Bitspeed.lastdata = Bitspeed.nowdata
            Bitspeed.LastDelta = Bitspeed.NowDelta
        })
        gcdTimer?.schedule(deadline: .now(), repeating: 1.5, leeway: .seconds(1))
        //gcdTimer?.schedule(deadline: .now() + 1)
        gcdTimer?.resume()
    }
    
    func freshButton() {
        if let button = statusItem.button {
            button.subviews.removeAll()
        }
        if let button = statusItem.button {
            let frame = NSRect(x: 0, y: 0, width:20, height: 22)
            let progressIndicator = MyProgress(frame: frame)
            progressIndicator.theme = theme
            progressIndicator.MinValue = 0
            progressIndicator.MaxValue = 500
            progressIndicator.MidValue = Bitspeed.NowDelta
            button.addSubview(progressIndicator)
        }
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        let statusBar = NSStatusBar.system
        statusBar.removeStatusItem(statusItem)
        
    }


}

extension AppDelegate:NSMenuDelegate{
    func menuDidClose(_ menu: NSMenu) {
        self.statusItem.menu = nil
    }
}
