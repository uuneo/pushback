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
		
		guard var level = bestAttemptContent.userInfo["level"] as? String else {
			return bestAttemptContent
		}
		
		// 重要警告 默认音量
		var audioVolume: Float = 0.5
		
		// MARK: - 增加调用的便捷性，level如果传入的是数字，按照数字逻辑处理通知级别和音量大小
		/// 0 : passive
		/// 1 : timeSensitive
		/// 2...10:  critical  大于1的都视为 "critical" 情况
		if let levelNumber = Int(level){
			switch levelNumber{
			case ..<0:
				level = "active"
			case 0:
				level = "passive"
			case 1:
				level = "timeSensitive"
			case 2...:
				level = "critical"
			default:
				level = "active"
				
			}
			audioVolume = max(0.1, min(1, Float(levelNumber) / 10.0))
		}
		
		
		// 兼容bark的使用方法 重要警告
		if level == "critical" {
			
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
			bestAttemptContent.interruptionLevel = .critical
			return bestAttemptContent
		}
		
		
		let interruptionLevels: [String: UNNotificationInterruptionLevel] = [
			"passive": .passive, "active": .active, "timesensitive": .timeSensitive, "timesenSitive": .timeSensitive,
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
