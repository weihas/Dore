//
//  AppDelegate.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/24.
//

import SwiftUI
import Foundation


@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        launchTask()
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

extension AppDelegate{
    
    func launchTask() {
        let Control = StatusItem()
        let SettingItems = SettingItems()
        Control.creatStatusBarItem()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Dore Settings")
        window.contentView = NSHostingView(rootView: SettingView(viewmodel: SettingItems))
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.delegate = self
    }
    
    
    static func openSettingPane() {
        (NSApp.delegate as! AppDelegate).window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
