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
	@ObservedObject var manager = PushbackManager.shared
	
	let iapService: IAPService
	
	
	init() {
		RevenueCatService.configOnLaunch()
		iapService = RevenueCatService()
	}
	var body: some Scene {
		WindowGroup {
			RootView{
				ContentView()
			}
			.environmentObject(PushbackManager.shared)
			.task {
				do {
					try await iapService.monitoringSubscriptionInfoUpdates { [weak manager] newInfo in
						guard let manager = manager else{ return }
						DispatchQueue.main.async {
							manager.premiumSubscriptionInfo = newInfo
						}
						debugPrint(newInfo)
					}
				} catch {
					Logger.iapService.error("Error on handling customer info updates: \(error, privacy: .public)")
				}
			}
		}
	}
}
