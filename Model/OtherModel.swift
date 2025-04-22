//
//  OtherModel.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import SwiftUI
import Defaults
import Foundation
import Kingfisher


// MARK: - Remote Response
struct baseResponse<T>: Codable where T: Codable{
	var code:Int
	var message:String
	var data:T?
	var timestamp:Int?
}

struct DeviceInfo: Codable {
	var deviceKey: String
	var deviceToken: String

	// 使用 `CodingKeys` 枚举来匹配 JSON 键和你的变量命名
	enum CodingKeys: String, CodingKey {
		case deviceKey = "key"
		case deviceToken = "token"
	}
}

enum requestHeader :String {
	case https = "https://"
	case http = "http://"
}

enum Identifiers {
	static let reminderCategory = "myNotificationCategory"
    static let markdownCategory = "markdown"
	static let copyAction = "copy"
    static let muteAction = "mute"
}

// MARK: - Page model


enum SubPage: Equatable{
	case customKey
	case servers
	case scan
	case music
	case appIcon
	case imageCache
    case assistant
	case web(String)
    case chatgpt(String)
    case cloudIcon
    case paywall
	case none
    
}

enum MessageStatckPage: Hashable {
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto
}

enum SettingStatckPage: Hashable {
    case server
    case assistantSetting
    case sound
    case privacy
    case privacyConfig
    case more
}


enum AllPage: Hashable {
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto
    
    
    case server
    case assistantSetting
    case privacy
    case privacyConfig
    case more
}





enum TabPage :String{
	case message = "message"
	case setting = "setting"
}

// MARK: - MessageAction model

enum MessageAction: String, CaseIterable, Equatable{
	case markRead = "allMarkRead"
	case lastHour = "hourAgo"
	case lastDay = "dayAgo"
	case lastWeek = "weekAgo"
	case lastMonth = "monthAgo"
	case allTime = "allTime"
	case cancel = "cancel"
	
	var localized:String{
		switch self {
		case .markRead: String(localized: "全部已读")
		case .lastHour: String(localized: "一小时前")
		case .lastDay: String(localized: "一天前")
		case .lastWeek: String(localized: "一周前")
		case .lastMonth: String(localized: "一月前")
		case .allTime: String(localized: "所有时间")
		case .cancel: String(localized: "取消")
		}
	}
	
	var date:Date{
		switch self {
		case .lastHour: Date().someHourBefore(1)
		case .lastDay: Date().someDayBefore(0)
		case .lastWeek: Date().someDayBefore(7)
		case .lastMonth: Date().someDayBefore(30)
		case .allTime: Date()
		default: Date().s1970
		}
	}
	
}


// MARK: - QuickAction model

enum QuickAction{
	static var selectAction:UIApplicationShortcutItem?

	static var allShortcutItems = [
		UIApplicationShortcutItem(
			type: "allread",
			localizedTitle: String(localized:  "已读全部") ,
			localizedSubtitle: "",
			icon: UIApplicationShortcutIcon(systemImageName: "bookmark"),
			userInfo: ["name":"allread" as NSSecureCoding]
		),
		UIApplicationShortcutItem(
			type: "alldelread",
			localizedTitle: String(localized: "删除全部已读"),
			localizedSubtitle: "",
			icon: UIApplicationShortcutIcon(systemImageName: "trash"),
			userInfo: ["name":"alldelread" as NSSecureCoding]
		),
		UIApplicationShortcutItem(
			type: "alldelnotread",
			localizedTitle: String(localized:  "删除全部未读"),
			localizedSubtitle: "",
			icon: UIApplicationShortcutIcon(systemImageName: "trash"),
			userInfo: ["name":"alldelnotread" as NSSecureCoding]
		)
	]
}

// MARK: - PushServerModel

struct PushServerModel: Codable, Identifiable,Equatable, Defaults.Serializable, Hashable{
	var id:String = UUID().uuidString
	var url:String
	var key:String = ""
	var status:Bool = false
	var createDate:Date = .now
	var updateDate:Date = .now

	var name:String{
		var name = url
		if let range = url.range(of: "://") {
		   name.removeSubrange(url.startIndex..<range.upperBound)
		}
		return name
	}
	
	var color: Color{ status ? .green : .orange }
    
    func server() -> String{
        return self.url + "/" + self.key
    }

}

// MARK: - BadgeAutoMode

enum BadgeAutoMode:String, CaseIterable,Defaults.Serializable {
	case auto = "Auto"
	case custom = "Custom"
}

// MARK: - CryptoMode

enum CryptoMode: String, Codable,CaseIterable, RawRepresentable, Defaults.Serializable {
	
	case CBC, ECB, GCM
	var padding: String {
		self == .GCM ? "Space" : "PKCS7"
	}

	
}

enum CryptoAlgorithm: Int, Codable, CaseIterable,RawRepresentable, Defaults.Serializable {
	case AES128 = 16 // 16 bytes = 128 bits
	case AES192 = 24 // 24 bytes = 192 bits
	case AES256 = 32 // 32 bytes = 256 bits
	
	var name:String{
		self == .AES128 ? "AES128" : (self == .AES192 ? "AES192" : "AES256")
	}
}

struct CryptoModel: Equatable, Codable, Defaults.Serializable{

	var algorithm: CryptoAlgorithm
	var mode: CryptoMode
	var key: String
	var iv: String

	static let data = CryptoModel(algorithm: .AES256, mode: .GCM, key: "KXkwFRs2ttGJi7mJdJk9AsjAF4jbr135", iv: "xBCSyAxsjkdrjFCa")

	static func generateRandomString(_ length: Int = 16) -> String {
		// 创建可用字符集（大写、小写字母和数字）
		let charactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
		
		return String(Array(1...length).compactMap { _ in charactersArray.randomElement() })
	}
	
}



// MARK: - AppIconMode

enum AppIconEnum:String, CaseIterable,Equatable,Defaults.Serializable{
	case pushback
    case Whale
    case bell
    
	

    var name: String? { self == .pushback ? nil : self.rawValue }
    
    var logo: String{
        switch self {
        case .pushback:
            return "logo"
        case .bell:
            return "logo1"
        case .Whale:
            return "logo2"
        }
    }
}

// MARK: - PushExampleModel

struct PushExampleModel:Identifiable {
	var id = UUID().uuidString
	var header,footer,title: AnyView
	var params:String
	var index:Int
}



// MARK: - ExpirationTime



enum ExpirationTime: Int, CaseIterable, Defaults.Serializable, Equatable{
	case forever = 999999
	case month = 30
	case weekDay = 7
	case oneDay = 1
	case no = 0

	var days: Int{ self.rawValue }
	
	var title:String{
		switch self {
		case .no: String(localized: "不保存")
		case .oneDay: String(localized:"1天")
		case .weekDay: String(localized:"1周")
		case .month: String(localized:"1月")
		case .forever: String(localized: "长期")
		}
	}
	
	
}



enum DefaultBrowserModel: String, CaseIterable, Defaults.Serializable {
	case safari
	case app

	var title:String{
		switch self {
			case .safari: "Safari"
			case .app: String(localized: "内部")
		}
	}

}


struct AssistantAccount: Defaults.Serializable, Codable, Identifiable{
    var id:String = UUID().uuidString
    var current:Bool = false
    var timestamp:Date = .now
    var name:String = String(localized: "智能助手")
    var host:String
    var basePath:String
    var key:String
    var model:String
}


extension AssistantAccount{
    mutating func trimAssistantAccountParameters() {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        host = host.removeHTTPPrefix()
        basePath = basePath.trimmingCharacters(in: .whitespacesAndNewlines)
        key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        model = model.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
