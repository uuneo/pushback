//
//  LevelHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation


/// 通知中断级别
class LevelHandler: NotificationContentHandler {
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let levelNumber = bestAttemptContent.getLevel()


		
		// MARK: - 增加调用的便捷性，level如果传入的是数字，按照数字逻辑处理通知级别和音量大小


		if levelNumber >= 3{
			// 重要警告 默认音量
			let audioVolume = max(0.0, min(1, Float(levelNumber) / 10.0))

			if let sound = bestAttemptContent.soundName {
				bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
			} else {
				bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
			}
		}

		
		bestAttemptContent.interruptionLevel = self.getInterruptionLevel(from: levelNumber)

		return bestAttemptContent
	}

	func getInterruptionLevel(from levelNumber: Int) -> UNNotificationInterruptionLevel {
		// 根据数字值返回对应的中断级别
		switch levelNumber {
			case 0:
				return .passive
			case 1:
				return .active
			case 2:
				return .timeSensitive
			case 3...10:
				return .critical
			default:
				return .active
		}
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


	func getLevel() -> Int {
		// 获取用户信息中的 level 值
		if let level = self.userInfo["level"] as? String {
			// 尝试将 level1 转换为整数
			if let levelNumber = Int(level), (0...10).contains(levelNumber) {
				return levelNumber
			}

			// 使用 switch 语句判断不同的字符串值
			switch level.lowercased() {
				case "passive":
					return 0
				case "active":
					return 1
				case "timeSensitive":
					return 2
				case "critical":
					return 3
				default:
					return 1
			}
		}
		return 1 // 如果没有 level 信息，则返回默认值 1
	}


}
