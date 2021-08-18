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
    var statusItem :NSStatusItem!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setUpStatusBarItem()
    }
    
    func setUpStatusBarItem() {
        let Control = StatusItemControl()
        Control.creatStatusBarItem()
        self.statusItem = Control.statusItem
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
