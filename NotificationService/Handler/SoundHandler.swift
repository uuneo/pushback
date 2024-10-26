//
//  SoundHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/16.
//

import Foundation
import Defaults

class SoundHandler: NotificationContentHandler{
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        
        let sound = (bestAttemptContent.userInfo["aps"] as? [String: Any])?["sound"] as? String ?? ""
        
        guard sound.count == 0 else { return bestAttemptContent }
		
        
        bestAttemptContent.sound = UNNotificationSound(named:  .init(rawValue: "\(Defaults[.sound]).caf") )
        
        return bestAttemptContent
        
       
    }
}
