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
		let subtitle = alert?[Params.subtitle.name] as? String
		let body = alert?[Params.body.name] as? String
		let url = userInfo[Params.url.name] as? String
		let markdown = userInfo[Params.markdown.name] as? String
		let icon = userInfo[Params.icon.name] as? String
		let ttl = userInfo[Params.ttl.name] as? String
		let group = userInfo[Params.group.name] as? String ?? String(localized: "默认")
		let level = bestAttemptContent.getLevel()

		var userInfoString:String{

			if let userInfoData = try? JSONSerialization.data(withJSONObject: userInfo, options: [.prettyPrinted]),
			   let userInfo = String(data: userInfoData , encoding: .utf8){
				return userInfo
			}
			return ""
		}


		bestAttemptContent.threadIdentifier = group


		//  获取保存时间
		var saveDays:Int {
			if let isArchive = ttl, let saveDaysTem = Int(isArchive){
				return saveDaysTem
			}else{
				return Defaults[.messageExpiration].days
			}
		}
		//  保存数据到数据库
		if  saveDays != 0 , let realm{

			try? realm.write {
				let message = Message()
				message.title = title
				message.subtitle = subtitle
				message.body = body
				message.url = url
				message.markdown = decodeBase64(markdown)
				message.group = group
				message.icon = icon
				message.level = level
				message.image = mediaHandler(userInfo: userInfo, name: Params.image.name)
				message.video = mediaHandler(userInfo: userInfo, name: Params.video.name)
				message.createDate = Date()
				message.ttl = saveDays
				message.userInfo = userInfoString
				realm.add(message)
			}
		}

		return bestAttemptContent
	}



	func decodeBase64(_ base64String: String?)-> String?{
		guard let base64String = base64String else { return nil }
		if let decodedData = Data(base64Encoded: base64String),
		   let decodedString = String(data: decodedData, encoding: .utf8) {
			print("解码后的字符串: \(decodedString)")
			return decodedString
		}

		return nil
	}


	
}
