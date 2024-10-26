//
//  AutoCopyHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import SwiftUI

class AutoCopyHandler: NotificationContentHandler {
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        if userInfo["autocopy"] as? String == "1"
            || userInfo["automaticallycopy"] as? String == "1"
        {
            if let copy = userInfo["copy"] as? String {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = bestAttemptContent.body
            }
        }
        return bestAttemptContent
    }
}
