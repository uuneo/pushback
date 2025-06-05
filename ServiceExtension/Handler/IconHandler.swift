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

class IconHandler: NotificationContentHandler{
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        let userInfo = bestAttemptContent.userInfo
        
        
        guard let imageUrl:String = userInfo.raw(.icon) else { return bestAttemptContent}
        
        var localPath = await ImageManager.downloadImage(imageUrl)
        
        /// 获取icon 云图标
        if localPath == nil {
            
            let images = await CloudManager.shared.queryIcons(name: imageUrl)
            
            if let image = images.first, let icon = image.toPushIcon(), let previewImage = icon.previewImage, let data = previewImage.pngData() {
                
                await ImageManager.storeImage(data: data, key: imageUrl , expiration: .days(Defaults[.imageSaveDays].days))
                
                localPath =  await ImageManager.downloadImage(imageUrl)
                
            }
        }
        
        
        
        
        guard let localPath = localPath, let imageData = NSData(contentsOfFile: localPath) as? Data else{ return bestAttemptContent }
        
        
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
}
