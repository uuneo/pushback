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
		let alert = (userInfo[Params.aps.name] as? [String: Any])?[Params.alert.name] as? [String: Any]
		let title = alert?[Params.title.name] as? String
		let subtitle = alert?[Params.subtitle.name] as? String
		let body = alert?[Params.body.name] as? String
		let url = userInfo[Params.url.name] as? String
		let icon = userInfo[Params.icon.name] as? String
		let ttl = userInfo[Params.ttl.name] as? String
		let image = userInfo[Params.image.name] as? String
		let group = userInfo[Params.group.name] as? String ?? String(localized: "默认")
        let host = userInfo[Params.host.name] as? String
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
            
            if let message =  realm.objects(Message.self).first(where: {$0.id == id}){
                try? realm.write {
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
                    message.search = message.allString()
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
                    message.search = message.allString()
                    realm.add(message)
                }
            }
            
            
            
        }
        

		return bestAttemptContent
	}

}
