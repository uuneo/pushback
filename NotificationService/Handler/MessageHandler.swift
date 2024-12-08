//
//  MessageHandler.swift
//  pushback
//
//  Created by He Cho on 2024/11/23.
//

import Foundation
import SwiftyJSON
import Defaults


class MessageHandler: NotificationContentHandler{
	private lazy var realm: Realm? = {
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		return try? Realm()
	}()
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let userInfo = bestAttemptContent.userInfo
		let alert = (userInfo[Params.aps.name] as? [String: Any])?[Params.alert.name] as? [String: Any]
		let title = alert?[Params.title.name] as? String
		let body = alert?[Params.body.name] as? String
		let url = userInfo[Params.url.name] as? String
		
		let icon = userInfo[Params.icon.name] as? String
		let isArchive = userInfo[Params.isarchive.name] as? String
		let group = userInfo[Params.group.name] as? String ?? String(localized: "默认")
		let call = userInfo[Params.call.name] as? String
		let mode = (userInfo[Params.mode.name] as? String ?? call) ?? "999"
		
		var userInfoString:String{
			
			if let userInfoData = try? JSONSerialization.data(withJSONObject: userInfo, options: [.prettyPrinted]),
			   let userInfo = String(data: userInfoData , encoding: .utf8){
				debugPrint(userInfo)
				return userInfo
			}
			return ""
		}
		
		
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

				message.image = mediaHandler(userInfo: userInfo, name: Params.image.name)
				message.video = mediaHandler(userInfo: userInfo, name: Params.video.name)
				message.createDate = Date()
				message.saveDays = saveDays
				message.mode = mode
				message.userInfo = userInfoString
				realm.add(message)
			}
		}
	  
		return bestAttemptContent
	}
	
	
	
	
	
}
