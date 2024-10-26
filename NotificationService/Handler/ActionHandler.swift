//
//  ActionHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/11.
//

import Foundation



class ActionHandler: NotificationContentHandler{
    
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        
		guard let action = bestAttemptContent.userInfo["action"] as? String else {
			return  bestAttemptContent
		}
        self.mailAuto(bestAttemptContent.userInfo, action)
        return bestAttemptContent
    }
    
    
    // MARK: 发送邮件
    private func mailAuto(_ userInfo:[AnyHashable: Any],_ action: String){
        Task{
            if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
			   let jsonString = String(data: jsonData, encoding: .utf8)
			{
               
//                ToolsManager.shared.sendMail(title: "自动化\(action)", text: jsonString ?? "数据编码失败")
				debugPrint(jsonString)
            } else {
#if DEBUG
                print("转换失败")
#endif
//                ToolsManager.shared.sendMail( title: "自动化\(action)", text: "数据编码失败")
            }
        }
        
    }
}
