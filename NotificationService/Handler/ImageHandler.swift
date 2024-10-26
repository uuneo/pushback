//
//  ImageHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices


class ImageHandler:NotificationContentHandler{
	func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo
		guard let imageUrl = userInfo["image"] as? String,
			  let imageFileUrl = await ImageManager.fetchImage(from: imageUrl)  else {
			return bestAttemptContent
		}
		
        
        let copyDestUrl = URL(fileURLWithPath: imageFileUrl).appendingPathExtension("tmp")
        // 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
        try? FileManager.default.copyItem(
            at: URL(fileURLWithPath: imageFileUrl),
            to: copyDestUrl
        )
		
		// MARK: - 此处提示按照下面修改
		///  import MobileCoreServices
		///  import UniformTypeIdentifiers
		///  'kUTTypePNG' was deprecated in iOS 15.0: Use  UTType.png.identifier
        if let attachment = try? UNNotificationAttachment(
            identifier: "image",
            url: copyDestUrl,
            
            options: [UNNotificationAttachmentOptionsTypeHintKey:  UTType.png.identifier]
           
        ) {
            bestAttemptContent.attachments = [attachment]
        }
        return bestAttemptContent
    }
}

