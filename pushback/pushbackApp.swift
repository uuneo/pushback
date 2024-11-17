//
//  pushbackApp.swift
//  pushback
//
//  Created by He Cho on 2024/10/25.
//

import SwiftUI
import RevenueCat

@main
struct pushbackApp: SwiftUI.App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	init() {
		Purchases.logLevel = .info
		Purchases.configure(
			with: .init(withAPIKey: "appl_YxyORDctxiNiyaANzrzSLiFGkYJ")
				.with(userDefaults: DEFAULTSTORE)
		)
	}
	var body: some Scene {
		WindowGroup {
			RootView{
				ContentView()
					
			}
			.environmentObject(PushbackManager.shared)
		}
	}
}
