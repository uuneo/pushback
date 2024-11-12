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
		guard let level = bestAttemptContent.userInfo["level"] as? String else {
			return bestAttemptContent
		}
		
		// 重要警告
		if level == "critical" {
			// 默认音量
			var audioVolume: Float = 0.5
			// 指定音量，取值范围是 1 - 10 , 会转换成 0.1 - 1
			if let volume = bestAttemptContent.userInfo["volume"] as? String, let volume = Float(volume) {
				audioVolume = max(0.1, min(1, volume / 10.0))
			}
			// 设置重要警告 sound
			
			if let sound = bestAttemptContent.soundName {
				bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
			} else {
				bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
			}
			return bestAttemptContent
		}
		
		
		let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
			"passive": UNNotificationInterruptionLevel.passive,
			"active": UNNotificationInterruptionLevel.active,
			"timesensitive": UNNotificationInterruptionLevel.timeSensitive,
			"timesenSitive": UNNotificationInterruptionLevel.timeSensitive,
			"critical":UNNotificationInterruptionLevel.critical
		]
		bestAttemptContent.interruptionLevel = interruptionLevels[level] ?? .active
		return bestAttemptContent
	}
}

extension UNMutableNotificationContent {
	/// 是否是重要警告
	var isCritical: Bool {
		self.userInfo["level"] as? String == "critical"
	}

	/// 声音名称
	var soundName: String? {
		(self.userInfo["aps"] as? [AnyHashable: Any])?["sound"] as? String
	}
}
