//
//  LevelHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//

import Foundation


/// 通知中断级别
class LevelHandler: NotificationContentHandler {
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let levelNumber = bestAttemptContent.getLevel()
		if levelNumber >= 3{
            LevelHandler.setCriticalSound(content: bestAttemptContent)
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
			case 3...:
				return .critical
			default:
				return .active
		}
	}
}


extension UNMutableNotificationContent {
    /// 是否是重要警告
    var isCritical: Bool {
        (self.userInfo["level"] as? String)?.lowercased() == "critical"
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
				case "timesensitive":
					return 2
				case "critical":
					return 3
				default:
					return 1
			}
		}
		return 1 // 如果没有 level 信息，则返回默认值 1
	}


	func getVolume(levelNumber: Int) -> Float{

		if let volume = self.userInfo["volume"] as? String, let volume = Float(volume) {
			return max(0.0, min(1, volume / 10.0))
		}
        
		return max(0.0, min(1, Float(levelNumber) / 10.0))

	}


}


extension LevelHandler{
    class func setCriticalSound(content bestAttemptContent: UNMutableNotificationContent, soundName: String? = nil) {
        guard bestAttemptContent.isCritical else {
            return
        }
        // 默认音量
        let audioVolume: Float = bestAttemptContent.getVolume(levelNumber: bestAttemptContent.getLevel())
        // 设置重要警告 sound
        let sound = soundName ?? bestAttemptContent.soundName
        if let sound {
            bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName(rawValue: sound), withAudioVolume: audioVolume)
        } else {
            bestAttemptContent.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: audioVolume)
        }
    }
}
