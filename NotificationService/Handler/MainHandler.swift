//
//  MainHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
@_exported import UserNotifications


enum NotificationContentHandlerItem: CaseIterable {
    case ciphertext
    case sound
    case level
	case autoCopy
	case archive
	case badge
    case setIcon
    case setImage
	case video
    case action
    case call
    
    
    
    var processor: NotificationContentHandler {
        switch self {
        case .ciphertext:
            return CiphertextHandler()
        case .level:
            return LevelHandler()
		case .badge:
			return BadgeProcessor()
        case .autoCopy:
            return AutoCopyHandler()
        case .archive:
            return ArchiveHandler()
        case .setIcon:
            return IconHandler()
        case .setImage:
            return ImageHandler()
        case .call:
            return CallHandler()
        case .action:
            return ActionHandler()
        case .sound:
            return SoundHandler()
        case .video:
            return VideoHandler()
    
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
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent
    
    /// serviceExtension 即将终止，不管 processor 是否处理完成，最好立即调用 contentHandler 交付已完成的部分，否则会原样展示服务器传递过来的推送
    func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void)
}

extension NotificationContentHandler {
    func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void) {}
}
