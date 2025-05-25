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
import cmark_gfm
import UserNotifications

class ActionHandler: NotificationContentHandler{
	
	private lazy var realm: Realm? = {
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		return try? Realm()
	}()
	
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        // MARK: - 处理 Ringtone
        if bestAttemptContent.soundName == nil && bestAttemptContent.getLevel() < 3{
            bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(Defaults[.sound]).caf" ))
        }
        
        // MARK: - markdownbody body 显示
        if bestAttemptContent.categoryIdentifier == Identifiers.markdownCategory{
            bestAttemptContent.body =  String(localized: "下拉查看详情...")
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
            if let badgeStr:String = bestAttemptContent.userInfo.raw(.badge), let badge = Int(badgeStr) {
                bestAttemptContent.badge = NSNumber(value: badge)
            }
        }

		// MARK: - 删除过期消息
		if let realm = realm{
			let messages = realm.objects(Message.self).filter({$0.isExpired()})
			try? realm.write{
                realm.delete( messages )
			}
		}
        
        // MARK: - 静音分组
        for setting in Defaults[.muteSetting] {
            if setting.value < Date() {
                Defaults[.muteSetting].removeValue(forKey: setting.key)
            }
        }

        if let date = Defaults[.muteSetting][bestAttemptContent.threadIdentifier], date > Date(){
            bestAttemptContent.interruptionLevel = .passive
        }
        
        // MARK: -  回调
        let http = NetworkManager()
        if let host:String = bestAttemptContent.userInfo.raw(.host),
           let id = bestAttemptContent.targetContentIdentifier,
           let url = http.appendQueryParameter(to: host, key: "id", value: id){
            http.fetchVoid(url: url)
        }
        
        
        if Defaults[.voicesAutoPreloading]{
            let text = bestAttemptContent.userInfo.voiceText()
            let client = try VoiceManager()
            let _ = try await client.createVoice(text: text)
        }
        
        if let widget:String = bestAttemptContent.userInfo.raw(.widget), let _ = URL(string: widget){
            Defaults[.widgetURL] = widget
        }
        
        return bestAttemptContent
        
    
	}
}



