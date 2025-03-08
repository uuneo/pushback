//
//  ImageHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import SwiftUI
import AVFoundation

class MediaHandler:NotificationContentHandler{
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo

		
		// 处理视频的情况
		if let videoUrlString = userInfo[Params.video.name] as? String,
		   let videoUrl = URL(string: videoUrlString) {
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
		
		
		
		if let imageUrl =  userInfo[Params.image.name] as? String{

			let cacheTag = Defaults[.images].filter({$0.url == imageUrl}).count == 0

			guard let localPath = await ImageManager.downloadImage(imageUrl) else {
				
				return bestAttemptContent
			}

			/// 自动保存图片到相册 前提 打开了自动存储，并且缓存内没有的图片
			if let uiimage = UIImage(contentsOfFile: localPath), Defaults[.autoSaveToAlbum], cacheTag{
				UIImageWriteToSavedPhotosAlbum(uiimage, self, nil, nil)
			}

			
			let copyDestUrl = URL(fileURLWithPath: localPath).appendingPathExtension(".tmp")
			// 将图片缓存复制一份，推送使用完后会自动删除，但图片缓存需要留着以后在历史记录里查看
			try? FileManager.default.copyItem(
				at: URL(fileURLWithPath: localPath),
				to: copyDestUrl
			)
			
			
			// MARK: - 此处提示按照下面修改
			///  import MobileCoreServices
			///  import UniformTypeIdentifiers
			///  'kUTTypePNG' was deprecated in iOS 15.0: Use  UTType.png.identifier
			let attachment = try UNNotificationAttachment(
				identifier: Params.image.name,
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
		   
		   // 设置提取的时间点（视频的第1秒）
		   let time = CMTimeMakeWithSeconds(1, preferredTimescale: 600)
		   
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

