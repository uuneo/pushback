//
//  ActionHandler.swift
//  pushback
//
//  Created by uuneo 2024/11/14.
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
		
		
		
		// MARK: - 处理 badge
		switch Defaults[.badgeMode] {
		case .auto:
			// MARK: 通知角标 .auto
			if let messages = realm?.objects(Message.self).where({!$0.read}){
				bestAttemptContent.badge = NSNumber(value:  messages.count)
			}
			
		case .custom:
			// MARK: 通知角标 .custom
				if let badgeStr = userInfo[Params.badge.name] as? String, let badge = Int(badgeStr) {
				bestAttemptContent.badge = NSNumber(value: badge)
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
        
        // 静音分组
        
        for setting in Defaults[.muteSetting] {
            if setting.value < Date() {
                Defaults[.muteSetting].removeValue(forKey: setting.key)
            }
        }

        if let date = Defaults[.muteSetting][bestAttemptContent.threadIdentifier], date > Date(){
            bestAttemptContent.interruptionLevel = .passive
        }
        
        
        return bestAttemptContent
        
    
	}
	
    
   

}



