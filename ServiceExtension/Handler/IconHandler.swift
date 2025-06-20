//
//  IconHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//

import Foundation
import Intents
import Defaults
import UserNotifications
import UIKit

class IconHandler: NotificationContentHandler{
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        
        
        guard let imageUrl:String = userInfo.raw(.icon) else { return bestAttemptContent}
        
        var localPath = await ImageManager.downloadImage(imageUrl)
        
        /// 获取icon 云图标
        if localPath == nil {
            
            let images = await IconCloudManager.shared.queryIcons(name: imageUrl)
            
            if let image = images.first, let icon = image.toPushIcon(), let previewImage = icon.previewImage, let data = previewImage.pngData() {
                
                await ImageManager.storeImage(data: data, key: imageUrl , expiration: .days(Defaults[.imageSaveDays].days))
                
                localPath =  await ImageManager.downloadImage(imageUrl)
                
            }
        }
        
        
        var imageData: Data?{
            if let localPath = localPath, let localImageData = NSData(contentsOfFile: localPath) as? Data{
                return localImageData
            }else{
                return avatarImage(from: imageUrl)?.pngData()
            }
        }
        
        guard let imageData = imageData else { return bestAttemptContent }
        
        
        let avatar = INImage(imageData: imageData)
        var personNameComponents = PersonNameComponents()
        personNameComponents.nickname = bestAttemptContent.title
        
        
        let senderPerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: personNameComponents,
            displayName: personNameComponents.nickname,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: false,
            suggestionType: .none
        )
        let mePerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: nil,
            displayName: nil,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: true,
            suggestionType: .none
        )
   
        let placeholderPerson = INPerson(
            personHandle: INPersonHandle(value: "", type: .unknown),
            nameComponents: personNameComponents,
            displayName: personNameComponents.nickname,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil
        )
        
        let intent = INSendMessageIntent(
            recipients: [mePerson, placeholderPerson],
            outgoingMessageType: .outgoingMessageText,
            content: bestAttemptContent.body,
            speakableGroupName: INSpeakableString(spokenPhrase: bestAttemptContent.subtitle),
            conversationIdentifier: bestAttemptContent.threadIdentifier,
            serviceName: nil,
            sender: senderPerson,
            attachments: nil
        )
        
        intent.setImage(avatar, forParameterNamed: \.speakableGroupName)
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        
        do {
            try await interaction.donate()
            let content = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
            return content
        } catch {
            return bestAttemptContent
        }
    }

    func avatarImage(from text: String, size: CGFloat = 300) -> UIImage? {
        
        // 准备文字
        let displayText = String(text.prefix(1))
        let singleEmoji = displayText.first?.isEmoji ?? false
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        var backgroundColor: UIColor{
            singleEmoji ? .clear : .systemBlue
        }
       
        return renderer.image { context in
            // 画圆形背景
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)
            
            // 设置字体
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize:  size * ( singleEmoji ? 1 : 0.85),
                                         weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            // 计算文字大小
            let textSize = displayText.size(withAttributes: attributes)
            let textOrigin = CGPoint(x: (size - textSize.width) / 2,
                                     y: (size - textSize.height) / 2)
            
            // 画文字
            displayText.draw(at: textOrigin, withAttributes: attributes)
        }
    }
    

}

extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
               (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars.count > 1)
    }
}
