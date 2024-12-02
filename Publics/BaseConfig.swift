//
//  BaseConfig.swift
//  pushback
//
//  Created by He Cho on 2024/10/25.
//

import Foundation
import UIKit

let DEFAULTSTORE = UserDefaults(suiteName: BaseConfig.groupName)!
let ISPAD = UIDevice.current.userInterfaceIdiom == .pad

class BaseConfig {
	static let  groupName = "group.pushback"
	static let 	icloudName = "iCloud.pushback"
	static let  settingName = "cryptoSettingFields"
	static let  deviceToken = "deviceToken"
	static let  imageCache = "pushback"
	static let  badgemode = "Meowbadgemode"
	static let  server = "serverArrayStroage"
	static let  defaultPage = "defaultPageViewShow"
	static let  messageFirstShow = "messageFirstShow"
	static let  messageShowMode = "messageShowMode"
	static let  syncServerUrl = "syncServerUrl"
	static let  syncServerParams = "syncServerParams"
	static let  emailConfig = "emailStmpConfig"
	static let  firstStartApp = "firstStartApp"
	static let  CryptoSettingFields = "CryptoSettingFields"
	static let  recordType = "NotificationMessage"
	static let  realmName = "Meowrld.realm"
	static let  kStopCallHandlerKey = "stopCallHandlerNotification"
	static let  Sounds = "Sounds"
	static let  realmModalVersion:UInt64 = 25
	static let  defaultSound = "defaultSound"
	static let  activeAppIcon = "setting_active_app_icon"
	static let 	customPhotoName = "CustomPhotoName"
	static let 	imagsList = "customImagesCache"
	static let 	RingTongRecord = "RingTongRecord"
	static let 	messageExpirtion = "messageExpirtionTime"
	static let  imageSaveDays = "imageSaveDays"
	static let 	photoName = "pushback."
	
	
#if DEBUG
	static let defaultServer = "https://dev.uuneo.com"
#else
	static let defaultServer = "https://push.uuneo.com"
#endif
	static let docServer = "https://pushback.uuneo.com"
	static let defaultImage = docServer + "/_media/avatar.jpg"
	static let helpWebUrl = docServer + "/#/tutorial"
	static let problemWebUrl = docServer + "/#/faq"
	static let delpoydoc = docServer + "/#/?id=pushback"
	static let emailHelpUrl = docServer + "/#/email"
	static let helpRegisterWebUrl = docServer + "/#/registerUser"
	static let musicUrl = "https://convertio.co/mp3-caf/"
	static let callback = defaultServer + "/callback"
	static let iconRemote = "https://pushback.uuneo.com/_media/avatar.png"
	
	static let testData = "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"telegraph\"}"

	
	/// 获取共享目录下的 Sounds 文件夹，如果不存在就创建
	static func getSoundsGroupDirectory() -> URL? {
		let manager = FileManager.default
		if let directoryUrl = manager.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)?.appendingPathComponent(BaseConfig.Sounds) {
			if !manager.fileExists(atPath: directoryUrl.path) {
				try? manager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
			}
			return directoryUrl
		}
		return nil
	}
	
	/// 获取 Library 目录下的 Sounds 文件夹
	/// 如果不存在就创建
	static func getSoundslibraryDirectory() -> URL? {
		let manager = FileManager.default
		guard let libraryDirectory = manager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
		
		let soundsDirectoryUrl = libraryDirectory.appendingPathComponent(BaseConfig.Sounds)
		
		if !manager.fileExists(atPath:soundsDirectoryUrl.path){
			try? manager.createDirectory(atPath: soundsDirectoryUrl.path, withIntermediateDirectories: true, attributes: nil)

		}
		return soundsDirectoryUrl
	}
	
	
	// Get the directory to store images in the App Group
	static func getImagesDirectory() -> URL? {
		guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName) else {
			return nil
		}
		let imagesDirectory = containerURL.appendingPathComponent("Images")
		
		// If the directory doesn't exist, create it
		if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
			do {
				try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print("Failed to create images directory: \(error.localizedDescription)")
				return nil
			}
		}
		return imagesDirectory
	}
	
	
	
	
	
	
	
	
	static func stopCallNotificationHandler(mode: String = "app") {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(kStopCallHandlerKey as CFString), nil, ["viewType": mode ] as CFDictionary, true)
	}
	
}
