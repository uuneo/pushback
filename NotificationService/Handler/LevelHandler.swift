//
//  LevelHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation


/// 通知中断级别
class LevelHandler: NotificationContentHandler {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		if let level = bestAttemptContent.userInfo["level"] as? String {
			let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
				"passive": UNNotificationInterruptionLevel.passive,
				"active": UNNotificationInterruptionLevel.active,
				"timeSensitive": UNNotificationInterruptionLevel.timeSensitive,
				"timesensitive": UNNotificationInterruptionLevel.timeSensitive,
				"critical": UNNotificationInterruptionLevel.critical
			]
			bestAttemptContent.interruptionLevel = interruptionLevels[level] ?? .active
		}
        return bestAttemptContent
    }
}
