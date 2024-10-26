//
//  BadgeHandler.swift
//  upush
//
//  Created by He Cho on 2024/10/10.
//

import Foundation
import Defaults


/// 通知角标
class BadgeProcessor: NotificationContentHandler {
	
	private lazy var realm: Realm? = {
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		return try? Realm()
	}()
	
	func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		if let badgeStr = bestAttemptContent.userInfo["badge"] as? String, let badge = Int(badgeStr) {
			bestAttemptContent.badge = NSNumber(value: badge)
		}
		
		switch Defaults[.badgeMode] {
		case .auto:
			// MARK: 通知角标 .auto
			let messages = realm?.objects(Message.self).where {!$0.read}
			bestAttemptContent.badge = NSNumber(value:  messages?.count ?? 1)
		case .custom:
			// MARK: 通知角标 .custom
			if let badgeStr = bestAttemptContent.userInfo["badge"] as? String, let badge = Int(badgeStr) {
				bestAttemptContent.badge = NSNumber(value: badge)
			}
		}
		
		
		
		
		return bestAttemptContent
	}
}
