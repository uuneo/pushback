//
//  VideoHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/9/1.
//

import Foundation
import UniformTypeIdentifiers
import UIKit

// 暂时不使用video缓存
class VideoHandler: NotificationContentHandler{
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        
        let userInfo = bestAttemptContent.userInfo
        
        
        guard let videoUrl = userInfo["video"] as? String else {
            return bestAttemptContent
        }
        
        debugPrint(videoUrl)
        
        // 从 Assets 中加载图片
        guard let image = UIImage(named: "video") else {
			
            print("Image not found in assets: video")
            return bestAttemptContent
        }
		
		debugPrint(image.size)
        
        // 将图片保存为临时文件
        guard let imageData = image.pngData() else {
            print("Failed to convert image to PNG data.")
            
            return bestAttemptContent
        }
        
        // 获取临时目录路径
        let tmpDirectory = FileManager.default.temporaryDirectory
        let tmpFileURL = tmpDirectory.appendingPathComponent("video.png")
        
        do {
            // 将数据写入临时文件
            try imageData.write(to: tmpFileURL)
            
            // 创建通知附件
            let attachment = try UNNotificationAttachment(
                identifier: "video",
                url: tmpFileURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
            )
            
            // 将附件添加到通知内容中
            bestAttemptContent.attachments = [attachment]
        } catch {
            return bestAttemptContent
        }
        return bestAttemptContent
    }
}

