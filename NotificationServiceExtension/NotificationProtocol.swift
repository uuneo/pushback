//
//  NotificationModel.swift
//  pushback
//
//  Created by uuneo 2024/11/23.
//

import Foundation


public protocol NotificationContentHandler {
	/// 处理 UNMutableNotificationContent
	/// - Parameters:
	///   - identifier: request.identifier, 有些 handler 需要，例如 Callhandler 需要这个去添加 LocalNotification
	///   - bestAttemptContent: 需要处理的 UNMutableNotificationContent
	/// - Returns: 处理成功后的 UNMutableNotificationContent
	/// - Throws: 处理失败后，应该中断处理
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent
	
	/// serviceExtension 即将终止，不管 handler 是否处理完成，最好立即调用 contentHandler 交付已完成的部分，否则会原样展示服务器传递过来的推送
	func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void)
}

extension NotificationContentHandler {
	func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void) {}
}



// enum 遵循CaseIterable 所以所有的 handler， 按顺序从上往下对推送进行处理
// ciphertext 需要放在最前面，有可能所有的推送数据都在密文里
// call 需要放在最后面，因为这个 handler 不会主动退出， 会一直等到 ServiceExtension 被终止
enum NotificationContentHandlerItem: CaseIterable {

	case ciphertext
	case message
	case icon
	case media
	case level
    case action
	case call
	
	
	
    var handler: NotificationContentHandler {
        switch self {
        case .ciphertext:
            return CiphertextHandler()
        case .message:
            return MessageHandler()
        case .level:
            return LevelHandler()
        case .icon:
            return IconHandler()
        case .media:
            return MediaHandler()
        case .action:
            return ActionHandler()
        case .call:
            return CallHandler()
        }
	}
}

enum NotificationContentHandlerError: Swift.Error {
	case error(content: UNMutableNotificationContent)
	case call
}
