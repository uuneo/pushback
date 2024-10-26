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
    
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        

		
        var isArchive: Bool = Defaults[.isMessageStorage]
        if let archive = userInfo["isarchive"] as? String {
            isArchive = archive == "1" ? true : false
        }
        
        if  isArchive {
            
            let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
            let title = alert?["title"] as? String
            let body = alert?["body"] as? String
            let url = userInfo["url"] as? String
            let group = userInfo["group"] as? String 
            let icon = userInfo["icon"] as? String
            
            if group == nil{
				bestAttemptContent.threadIdentifier = String(localized: "默认")
            }
            
            var mode:String? {
                if let mode = userInfo["mode"] as? String{
                    return mode
                }
                if let call = userInfo["call"] as? String, call == "1"{
                    return call
                }
                return nil
            }
            
            
            try? realm?.write {
                let message = Message()
                message.title = title
                message.body = body
                message.url = url
				if let group {
					message.group = group
				}
                message.icon = icon
                message.createDate = Date()
				if let mode {
					message.mode = mode
				}
                realm?.add(message)
            }
        }
		
      
        return bestAttemptContent
    }
}
