//
//  NotificationService.swift
//  NotificationService
//
//  Created by He Cho on 2024/10/26.
//

import UserNotifications
import Foundation
@_exported import UserNotifications

// 所有的 processor， 按顺序从上往下对推送进行处理
// ciphertext 需要放在最前面，有可能所有的推送数据都在密文里
// call 需要放在最后面，因为这个 Processor 不会主动退出， 会一直等到 ServiceExtension 被终止
enum NotificationContentHandlerItem: CaseIterable {
	case ciphertext
	case archive
	case icon
	case media
	case level
	case action
	case call
	
	
	var processor: NotificationContentHandler {
		switch self {
		case .ciphertext:
			return CiphertextHandler()
		case .level:
			return LevelHandler()
		case .action:
			return ActionHandler()
		case .archive:
			return ArchiveHandler()
		case .icon:
			return IconHandler()
		case .media:
			return MediaHandler()
		case .call:
			return CallHandler()
	
		}
	}
}

enum NotificationContentHandlerError: Swift.Error {
	case error(content: UNMutableNotificationContent)
}

public protocol NotificationContentHandler {
	/// 处理 UNMutableNotificationContent
	/// - Parameters:
	///   - identifier: request.identifier, 有些 Processor 需要，例如 CallProcessor 需要这个去添加 LocalNotification
	///   - bestAttemptContent: 需要处理的 UNMutableNotificationContent
	/// - Returns: 处理成功后的 UNMutableNotificationContent
	/// - Throws: 处理失败后，应该中断处理
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent
	
	/// serviceExtension 即将终止，不管 processor 是否处理完成，最好立即调用 contentHandler 交付已完成的部分，否则会原样展示服务器传递过来的推送
	func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void)
}

extension NotificationContentHandler {
	func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void) {}
}

class NotificationService: UNNotificationServiceExtension {

	/// 当前正在运行的 Processor
	var currentNotificationProcessor: NotificationContentHandler? = nil
	/// 当前 ContentHandler，主要用来 serviceExtensionTimeWillExpire 时，传递给 Processor 用来交付推送。
	var currentContentHandler: ((UNNotificationContent) -> Void)? = nil

	
	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		Task {
			guard var bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
				contentHandler(request.content)
				return
			}
			self.currentContentHandler = contentHandler
			
			// 各个 processor 依次对推送进行处理
			for processor in NotificationContentHandlerItem.allCases.map({ $0.processor }) {
				do {
					self.currentNotificationProcessor = processor
					bestAttemptContent = try await processor.handler(identifier: request.identifier, content: bestAttemptContent)
				} catch NotificationContentHandlerError.error(let content) {
					contentHandler(content)
					return
				}
			}
			
			// 处理完后交付推送
			contentHandler(bestAttemptContent)
		}
	}
	
	override func serviceExtensionTimeWillExpire() {
		super.serviceExtensionTimeWillExpire()
		if let handler = self.currentContentHandler {
			self.currentNotificationProcessor?.serviceExtensionTimeWillExpire(contentHandler: handler)
		}
	}

}



