//
//  ActionHandler.swift
//  pushback
//
//  Created by He Cho on 2024/11/14.
//

import Foundation
import Intents
import Defaults
import SwiftUI

class ActionHandler: NotificationContentHandler{
	
	private lazy var realm: Realm? = {
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		return try? Realm()
	}()
	
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		
		
		let userInfo = bestAttemptContent.userInfo
		
		
		//  处理 自动复制 兼容bark用法
		if userInfo["autocopy"] as? String == "1" || userInfo["automaticallycopy"] as? String == "1"
		{
			if let copy = userInfo["copy"] as? String {
				UIPasteboard.general.string = copy
			} else {
				UIPasteboard.general.string = bestAttemptContent.body
			}
		}
		
		
		// MARK: - 处理 badge
		switch Defaults[.badgeMode] {
		case .auto:
			// MARK: 通知角标 .auto
			let messages = realm?.objects(Message.self).where {!$0.read}
			bestAttemptContent.badge = NSNumber(value:  messages?.count ?? 1)
		case .custom:
			// MARK: 通知角标 .custom
			if let badgeStr = userInfo["badge"] as? String, let badge = Int(badgeStr) {
				bestAttemptContent.badge = NSNumber(value: badge)
			}
		}
		
		
		// MARK: - 处理 Ringtone
		if let  sound = (userInfo["aps"] as? [String: Any])?["sound"] as? String , sound == ""{
			bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(Defaults[.sound].name).caf" ) )
		}
		
		return bestAttemptContent
	}
	
	

}



