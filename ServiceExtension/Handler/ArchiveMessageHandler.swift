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
        
        let group:String = userInfo.raw(.group) ?? String(localized: "默认")
        bestAttemptContent.threadIdentifier = group
        
        let ttl:String? = userInfo.raw(.ttl)
        let title:String? = userInfo.raw(.title)
        let subtitle:String? = userInfo.raw(.subtitle)
        let url:String? = userInfo.raw(.url)
        let icon:String? = userInfo.raw(.icon)
        let image:String? = userInfo.raw(.image)
        let host:String? = userInfo.raw(.host)
        let messageId = bestAttemptContent.targetContentIdentifier
        let level =  bestAttemptContent.getLevel()
        
        var body:String? {
            if let body:String = userInfo.raw(.body){
                /// 解决换行符渲染问题
                return DatabaseManager.ensureMarkdownLineBreaks(body)
            }
           return nil
        }
        
        //  获取保存时间
        var saveDays:Int {
            if let isArchive = ttl, let saveDaysTem = Int(isArchive){
                return saveDaysTem
            }else{
                return Defaults[.messageExpiration].days
            }
        }
        
        Defaults[.allMessagecount] += 1
        
        guard title != nil || subtitle != nil || body != nil else  {
            bestAttemptContent.interruptionLevel = .passive
            return bestAttemptContent
        }
        
        guard saveDays > 0 else { return bestAttemptContent }
        
        //  保存数据到数据库
        let message = Message(id: messageId ?? UUID().uuidString, group: group,
                              createDate: .now, title: title, subtitle: subtitle,
                              body: body, icon: icon, url: url, image: image,
                              host: host, level: Int(level), ttl: saveDays, read: false)
        
        Task.detached(priority: .userInitiated) {
            await DatabaseManager.shared.add(message)
        }
        
        return bestAttemptContent
    }
    
}
