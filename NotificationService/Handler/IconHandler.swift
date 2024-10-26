//
//  IconHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import Intents
import Defaults

class IconHandler: NotificationContentHandler{
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        if #available(iOSApplicationExtension 15.0, *) {
            let userInfo = bestAttemptContent.userInfo
			
            var avatar = INImage(named: Defaults[.appIcon].logo)
			

            if let imageUrl = userInfo["icon"] as? String,
			   let imageFileUrl = await ImageManager.fetchImage(from: imageUrl){
                
                avatar = INImage(imageData: NSData(contentsOfFile: imageFileUrl)! as Data)
                
            }else{
                guard userInfo["mode"] as? String == "1" || userInfo["call"] as? String == "1" else{
                    return bestAttemptContent
                }
            }
            
            
            
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
            
            let intent = INSendMessageIntent(
                recipients: [mePerson],
                outgoingMessageType: .outgoingMessageText,
                content: bestAttemptContent.body,
                speakableGroupName: INSpeakableString(spokenPhrase: personNameComponents.nickname ?? ""),
                conversationIdentifier: bestAttemptContent.threadIdentifier,
                serviceName: nil,
                sender: senderPerson,
                attachments: nil
            )
            
            intent.setImage(avatar, forParameterNamed: \.sender)
            
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            
            do {
                try await interaction.donate()
                let content = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
                return content
            } catch {
                return bestAttemptContent
            }
        } else {
            return bestAttemptContent
        }
    }
}
