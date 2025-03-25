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
    @StateObject private var manager = PushbackManager.shared
    @StateObject private var appstate = AppState.shared

	var body: some Scene {
		WindowGroup {
			RootView{
				ContentView()
					.disabled(manager.disabled)
			}
			.environmentObject(manager)
			.environmentObject(appstate)
      
		}
	}

}

