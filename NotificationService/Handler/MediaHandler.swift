//
//  ImageHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import SwiftUI
import AVFoundation

class MediaHandler:NotificationContentHandler{
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo
		
		
		
//		if bestAttemptContent.userInfo["video"] is String{
//			
//			
//			guard let uiImage = UIImage(named: "video"),
//				  let imageData = uiImage.pngData() else {
//				return bestAttemptContent
//			}
//			
//			
//			let temDir = FileManager.default.temporaryDirectory
//			
//			// Construct the full image path
//			let imagePath = temDir.appendingPathComponent("video.png")
//			
//			try imageData.write(to: imagePath)
//		
//			// 创建通知附件
//			let attachment = try UNNotificationAttachment(
//				identifier: "video",
//				url: imagePath,
//				options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
//			)
//			
//			// 将附件添加到通知内容中
//			bestAttemptContent.attachments = [attachment]
//		}
		
		// 处理视频的情况
		if let videoUrlString = userInfo["video"] as? String, let videoUrl = URL(string: videoUrlString) {
			// 获取视频的第一帧
			guard let uiImage = await getFirstFrameFromVideo(url: videoUrl) else {
				return bestAttemptContent
			}
			
			// 保存第一帧为图片
			guard let imageData = uiImage.pngData() else {
				return bestAttemptContent
			}
			
			let tempDir = FileManager.default.temporaryDirectory
			let imagePath = tempDir.appendingPathComponent("video_frame.png")
			
			try imageData.write(to: imagePath)
			
			// 创建通知附件
			let attachment = try UNNotificationAttachment(
				identifier: "video_frame",
				url: imagePath,
				options: [UNNotificationAttachmentOptionsTypeHintKey: UTType.png.identifier]
			)
			
			// 将附件添加到通知内容中
			bestAttemptContent.attachments = [attachment]
		}
		
		
		if let imageUrl = userInfo["image"] as? String{
			
			guard let imageFileUrl = await ImageManager.fetchImage(from: imageUrl) else {
				return bestAttemptContent
			}
			
			
			let copyDestUrl = URL(fileURLWithPath: imageFileUrl).appendingPathExtension(".tmp")
			// 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
			try? FileManager.default.copyItem(
				at: URL(fileURLWithPath: imageFileUrl),
				to: copyDestUrl
			)
			
			
			// MARK: - 此处提示按照下面修改
			///  import MobileCoreServices
			///  import UniformTypeIdentifiers
			///  'kUTTypePNG' was deprecated in iOS 15.0: Use  UTType.png.identifier
			let attachment = try UNNotificationAttachment(
				identifier: "image",
				url: copyDestUrl,
				
				options: [UNNotificationAttachmentOptionsTypeHintKey:  UTType.png.identifier]
			   
			)
			
			bestAttemptContent.attachments = [attachment]
			
			
			
		}
		
	
		return bestAttemptContent
    }
	
	// 获取视频的第一帧
	   private func getFirstFrameFromVideo(url: URL) async -> UIImage? {
		   let asset = AVAsset(url: url)
		   let assetImageGenerator = AVAssetImageGenerator(asset: asset)
		   assetImageGenerator.appliesPreferredTrackTransform = true
		   
		   // 设置提取的时间点（视频的第0秒）
		   let time = CMTimeMakeWithSeconds(3, preferredTimescale: 600)
		   
		   do {
			   // 同步提取第一帧
			   let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
			   return UIImage(cgImage: cgImage)
		   } catch {
			   print("Error generating video frame: \(error)")
			   return nil
		   }
	   }
}

