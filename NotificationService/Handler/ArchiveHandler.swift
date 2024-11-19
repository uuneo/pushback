//
//  ArchiveHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import SwiftyJSON
import Defaults

class ArchiveHandler: NotificationContentHandler{
    private lazy var realm: Realm? = {
        Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
        return try? Realm()
    }()
    
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
        let userInfo = bestAttemptContent.userInfo
		let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
		let title = alert?["title"] as? String
		let body = alert?["body"] as? String
		let url = userInfo["url"] as? String
		let icon = userInfo["icon"] as? String
		let isArchive = userInfo["isarchive"] as? String
		let group = userInfo["group"] as? String ?? String(localized: "默认")
		let call = userInfo["call"] as? String
		let mode = (userInfo["mode"] as? String ?? call) ?? "999"
		
		bestAttemptContent.threadIdentifier = group
		
		//  获取保存时间
		var saveDays:Int {
			if let isArchive = isArchive,  let saveDays = Int(isArchive){
				return saveDays == 1 ? -1 : saveDays
			}else{
				return Defaults[.messageExpiration].days
			}
		}
		//  保存数据到数据库
		if  saveDays != 0 , let realm{
            try? realm.write {
                let message = Message()
                message.title = title
                message.body = body
                message.url = url
				message.group = group
                message.icon = icon
                message.createDate = Date()
				message.saveDays = saveDays
				message.mode = mode
                realm.add(message)
            }
        }
		
      
        return bestAttemptContent
    }
}
