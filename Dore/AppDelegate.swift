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
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let ViewModel = StatusItemControl(statusItem)
        ViewModel.creatStatusBarItem()
        statusItem = ViewModel.statusItem
    }
    

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        let statusBar = NSStatusBar.system
        statusBar.removeStatusItem(statusItem)
        
    }

    
    @IBAction func itemAction(_ sender: AnyObject){
        print("Hello")
    }
    
    
}
