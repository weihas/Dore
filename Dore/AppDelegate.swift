//
//  AppDelegate.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/24.
//

import SwiftUI
import Foundation


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    lazy var window: NSWindow = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Dore Settings")
        window.contentView = NSHostingView(rootView: SettingView())
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        return window
    }()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let vm = StatusItemShow()
        vm.drawStatusBarItem()
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    static func openSettingPane() {
        guard let window = (NSApp.delegate as? AppDelegate)?.window else {return}
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
