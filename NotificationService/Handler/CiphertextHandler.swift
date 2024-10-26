//
//  CiphertextHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import Foundation
import SwiftyJSON
import Defaults


class CiphertextHandler: NotificationContentHandler {
    
    func process(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
        var userInfo = bestAttemptContent.userInfo
        guard let ciphertext = userInfo["ciphertext"] as? String else {
            return bestAttemptContent
        }
        
        // 如果是加密推送，则使用密文配置 bestAttemptContent
        do {
            var map = try self.decrypt(ciphertext: ciphertext, iv: userInfo["iv"] as? String)
            
            var alert = [String: Any]()
            var soundName: String? = nil
            if let title = map["title"] as? String {
                bestAttemptContent.title = title
                alert["title"] = title
            }
            if let body = map["body"] as? String {
                bestAttemptContent.body = body
                alert["body"] = body
            }
            if let group = map["group"] as? String {
                bestAttemptContent.threadIdentifier = group
            }
            if var sound = map["sound"] as? String {
                if !sound.hasSuffix(".caf") {
                    sound = "\(sound).caf"
                }
                soundName = sound
                bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sound))
            }
            if let badge = map["badge"] as? Int {
                bestAttemptContent.badge = badge as NSNumber
            }
            var aps: [String: Any] = ["alert": alert]
            if let soundName {
                aps["sound"] = soundName
            }
            map["aps"] = aps
        
            userInfo = map
            bestAttemptContent.userInfo = userInfo
            return bestAttemptContent
        } catch {
            bestAttemptContent.body = "Decryption Failed"
            bestAttemptContent.userInfo = ["aps": ["alert": ["body": bestAttemptContent.body]]]
            throw NotificationContentHandlerError.error(content: bestAttemptContent)
        }
    }
    
	// MARK: 解密
	func decrypt(ciphertext: String, iv: String? = nil) throws -> [AnyHashable: Any] {
		
		var fields = Defaults[.cryptoConfig]
		
		if let iv = iv {
			// Support using specified IV parameter for decryption
			fields.iv = iv
		}
		
		let aes = CryptoManager(fields)
		guard let textData = Data(base64Encoded: ciphertext),
			  let json = aes.decrypt(textData),
			  let data = json.data(using: .utf8),
			  let map = JSON(data).dictionaryObject
		else {
			throw "JSON parsing failed"
		}
		
		var result: [AnyHashable: Any] = [:]
		for (key, val) in map {
			// 将key重写为小写
			result[key.lowercased()] = val
		}
		return result
	}

}
