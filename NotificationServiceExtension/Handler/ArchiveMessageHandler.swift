//
//  MessageHandler.swift
//  pushback
//
//  Created by uuneo 2024/11/23.
//

import Foundation
import SwiftyJSON
import Defaults
import UserNotifications


class ArchiveMessageHandler: NotificationContentHandler{
	private lazy var realm: Realm? = {
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		return try? Realm()
	}()

	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {

        let userInfo = bestAttemptContent.userInfo
        let title:String? = userInfo.raw(.title)
        let subtitle:String? = userInfo.raw(.subtitle)
        let body:String? = userInfo.raw(.body)
        let url:String? = userInfo.raw(.url)
        let icon:String? = userInfo.raw(.icon)
        let ttl:String? = userInfo.raw(.ttl)
        let image:String? = userInfo.raw(.image)
        let group:String = userInfo.raw(.group) ?? String(localized: "默认")
        let host:String? = userInfo.raw(.host)
        let messageId = bestAttemptContent.targetContentIdentifier
        let level =  bestAttemptContent.getLevel()

		bestAttemptContent.threadIdentifier = group

		//  获取保存时间
		var saveDays:Int {
			if let isArchive = ttl, let saveDaysTem = Int(isArchive){
				return saveDaysTem
			}else{
				return Defaults[.messageExpiration].days
			}
		}
        
        var id:UUID{
            guard let messageId, let id = UUID(uuidString: messageId) else {  return  UUID() }
            return id
        }
        //  保存数据到数据库
        if  saveDays > 0, let realm{

            if let message = realm.objects(Message.self).first(where: {$0.id == id}){
                
                try? realm.write {
                    message.createDate = .now
                    message.title = title
                    message.subtitle = subtitle
                    message.body = body
                    message.url = url
                    message.group = group
                    message.icon = icon
                    message.level = Int(level)
                    message.image = image
                    message.createDate = Date()
                    message.ttl = saveDays
                    message.host = host
                }
            }else {
                try? realm.write {
                    let message = Message()
                    message.id = id
                    message.title = title
                    message.subtitle = subtitle
                    message.body = body
                    message.url = url
                    message.group = group
                    message.icon = icon
                    message.level = Int(level)
                    message.image = image
                    message.createDate = Date()
                    message.ttl = saveDays
                    message.host = host
                    realm.add(message)
                }
            }
        }
    
        Defaults[.allMessagecount] += 1

		return bestAttemptContent
	}

}
