//
//  IconHandler.swift
//  NotificationServiceExtension
//
//  Created by uuneo 2024/8/8.
//

import Foundation
import Intents
import Defaults

class IconHandler: NotificationContentHandler{
    func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		let userInfo = bestAttemptContent.userInfo
		
		
		guard  let imageUrl = userInfo[Params.icon.name] as? String,
			   let localPath = await ImageManager.downloadImage(imageUrl),
			   let imageData = NSData(contentsOfFile: localPath) as? Data else{
			return bestAttemptContent
		}
		
		
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
		
		try await interaction.donate()
		let content = try bestAttemptContent.updating(from: intent) as! UNMutableNotificationContent
		return content
    }
}
