//
//  File name:     MeoworldApp.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/24.
	

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

