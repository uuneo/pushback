//
//  pushbackApp.swift
//  pushback
//
//  Created by lynn on 2025/4/3.
//


import SwiftUI

@main
struct pushbackApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            RootView{
                ContentView()
            }
        }
    }

}


