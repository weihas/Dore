//
//  AppDelegate.swift
//  Dore
//
//  Created by WeIHa'S on 2020/11/24.
//

import SwiftUI
import ServiceManagement
import NetworkExtension

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem :NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var Settingwindow: NSWindow!
    
    @IBOutlet weak var Menu: NSMenu!
    
    
    @IBAction func Quit(_sender: Any){
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func ShowSettingView(_ sender: Any) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = SettingView()

        // Create the window and set the content view.
        Settingwindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        Settingwindow.isReleasedWhenClosed = true
        Settingwindow.center()
        Settingwindow.isRestorable = false
        Settingwindow.title = "Dore"
        Settingwindow.setFrameAutosaveName("Dore Window")
        Settingwindow.contentView = NSHostingView(rootView: contentView)
        Settingwindow.makeKeyAndOrderFront(nil)
    }
    
    
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let ViewModel = StatusItemControl(statusItem, Menu)
        ViewModel.creatStatusBarItem()
        statusItem = ViewModel.statusItem
    }
    

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        let statusBar = NSStatusBar.system
        statusBar.removeStatusItem(statusItem)
        
    }
    
    
}

extension AppDelegate: NSMenuDelegate{
    func menuDidClose(_ menu: NSMenu) {
        self.statusItem.menu = nil
    }
}
