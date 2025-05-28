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
        
        var id:String{
            if let messageId{ return messageId }
            else {  return  UUID().uuidString }
        }
        //  保存数据到数据库
        if  saveDays > 0{
            
            let message = Message(id: id, group: group, createDate: .now, title: title, subtitle: subtitle, body: body, icon: icon, url: url, image: image,  host: host, level: Int(level), ttl: saveDays, read: false)
            Task.detached(priority: .background) {
                await DatabaseManager.shared.add(message)
            }
            
        }

        Defaults[.allMessagecount] += 1

		return bestAttemptContent
	}

}
