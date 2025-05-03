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
    @StateObject private var manager = PushbackManager.shared
    @StateObject private var appstate = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            RootView{
                ContentView()
                    .disabled(manager.disabled)
                    .environmentObject(manager)
                    .environmentObject(appstate)
            }
        }
    }

}


