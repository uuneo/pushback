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
			if let messages = realm?.objects(Message.self).where({!$0.read}){
				bestAttemptContent.badge = NSNumber(value:  messages.count)
			}
			
		case .custom:
			// MARK: 通知角标 .custom
			if let badgeStr = userInfo["badge"] as? String, let badge = Int(badgeStr) {
				bestAttemptContent.badge = NSNumber(value: badge)
				// 清除通知中心的通知
				if badge == -1 {
					UNUserNotificationCenter.current().removeAllDeliveredNotifications()
				}
			}
		}

		// MARK: - 处理 Ringtone
		if bestAttemptContent.soundName == "" && bestAttemptContent.getLevel() < 3{
			bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(Defaults[.sound].name).caf" ) )
		}

		// MARK: - 删除过期消息
		if let realm = realm{
			let messages = realm.objects(Message.self).filter({$0.isExpired()})
			try? realm.write{
				for message in messages{
					realm.delete( message )
				}
			}
		}
		return bestAttemptContent
	}
	
	

}



