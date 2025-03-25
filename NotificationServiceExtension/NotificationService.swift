//
//  File name:     NotificationService.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/24.
	

@_exported import UserNotifications



class NotificationService: UNNotificationServiceExtension {

	/// 当前正在运行的
	var currentNotificationHandler: NotificationContentHandler? = nil
	/// 当前 ContentHandler，主要用来 serviceExtensionTimeWillExpire 时，传递给 handler 用来交付推送。
	var currentContentHandler: ((UNNotificationContent) -> Void)? = nil


	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        
    
        
		Task {
            guard var bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
                contentHandler(request.content)
                return
            }
            
            
            
			self.currentContentHandler = contentHandler
            
           

			// 各个 handler 依次对推送进行处理
			for handler in NotificationContentHandlerItem.allCases.map({ $0.handler }) {
				do {
					self.currentNotificationHandler = handler
					bestAttemptContent = try await handler.handler(identifier: request.identifier, content: bestAttemptContent)
				} catch NotificationContentHandlerError.error(let content) {
					contentHandler(content)
					return
				}
			}
            

			contentHandler(bestAttemptContent)
		}
	}

	override func serviceExtensionTimeWillExpire() {
		super.serviceExtensionTimeWillExpire()
		if let handler = self.currentContentHandler {
			self.currentNotificationHandler?.serviceExtensionTimeWillExpire(contentHandler: handler)
		}
	}

}
