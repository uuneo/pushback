//
//  pushbackApp.swift
//  pushback
//
//  Created by He Cho on 2024/10/25.
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
			.environmentObject(PushbackManager.shared)
		}
	}
}
