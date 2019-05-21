//
//  AppDelegate.swift
//  HumanGLAnimation
//
//  Created by Arthur MASSON on 5/17/19.
//  Copyright © 2019 Arthur MASSON. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func saveAnimation(_ sender: Any) {
        currentViewController?.saveAnimation(sender)
    }

    @IBAction func openAnimation(_ sender: Any) {
        currentViewController?.openAnimation(sender)
    }
    
}

