//
//  ImageHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices


class MediaHandler:NotificationContentHandler{
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo
		
		if let imageUrl = userInfo["image"] as? String{
			
			guard let imageFileUrl = await ImageManager.fetchImage(from: imageUrl) else {
				return bestAttemptContent
			}
			// MARK: - 此处提示按照下面修改
			///  import MobileCoreServices
			///  import UniformTypeIdentifiers
			///  'kUTTypePNG' was deprecated in iOS 15.0: Use  UTType.png.identifier
			let attachment = try UNNotificationAttachment(
				identifier: "image",
				url: URL(fileURLWithPath: imageFileUrl),
				
				options: [UNNotificationAttachmentOptionsTypeHintKey:  UTType.png.identifier]
			   
			)
			
			bestAttemptContent.attachments = [attachment]
			
			
			
		}else if  let videoUrl = bestAttemptContent.userInfo["video"] as? String{
			
			guard let fileUrl = Bundle.main.path(forResource: "video", ofType: "png"),
				  let imageUrl = URL(string: fileUrl)
			else {
				return bestAttemptContent
			}
			
			// 创建通知附件
			let attachment = try UNNotificationAttachment(
				identifier: "video",
				url: imageUrl,
				options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
			)
			
			// 将附件添加到通知内容中
			bestAttemptContent.attachments = [attachment]
		}
		
	
		return bestAttemptContent
    }
}

