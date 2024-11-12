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
	static let  kStopCallProcessorKey = "stopCallProcessorNotification"
	static let  Sounds = "Sounds"
	static let  isMessageStorage = "isMessageStorage"
	static let  realmModalVersion:UInt64 = 21
	static let  defaultSound = "defaultSound"
	static let  activeAppIcon = "setting_active_app_icon"
	static let 	customPhotoName = "CustomPhotoName"
	static let 	imagsList = "customImagesCache"
	static let 	RingTongRecord = "RingTongRecord"
	
	
	
#if DEBUG
	static let defaultServer = "https://dev.twown.com"
#else
	static let defaultServer = "https://push.twown.com"
#endif
	static let docServer = "https://pushback.twown.com"
	static let defaultImage = docServer + "/_media/avatar.jpg"
	static let helpWebUrl = docServer + "/#/tutorial"
	static let problemWebUrl = docServer + "/#/faq"
	static let delpoydoc = docServer + "/#/?id=pushback"
	static let emailHelpUrl = docServer + "/#/email"
	static let helpRegisterWebUrl = docServer + "/#/registerUser"
	static let musicUrl = "https://convertio.co/mp3-caf/"
	static let callback = defaultServer + "/callback"
	
	
}
