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

	var body: some Scene {
		WindowGroup {
			RootView{
				ContentView()
					.disabled(PushbackManager.shared.disabled)
			}
			.environmentObject(PushbackManager.shared)
			.environmentObject(AppState.shared)
		}
	}

}

