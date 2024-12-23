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
	@ObservedObject var manager = PushbackManager.shared
	@StateObject private var appState = AppState()

	var body: some Scene {
		WindowGroup {
			RootView{
				ContentView()

			}
			.environmentObject(PushbackManager.shared)
			.environmentObject(appState)
		}
	}
}

