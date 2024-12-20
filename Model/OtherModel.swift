//
//  OtherModel.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

import SwiftUI
import Defaults
import Foundation


// MARK: - Remote Response
struct baseResponse<T:Codable>: Codable{
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

struct ChangeKeyInfo:Codable{
	var oldKey:String
	var newKey:String
	var deviceToken:String
}





enum requestHeader :String {
	case https = "https://"
	case http = "http://"
}

struct Identifiers {
	static let reminderCategory = "myNotificationCategory"
	static let cancelAction = "cancel"
	static let copyAction = "copy"
	static let detailAction = "viewDetail"
}

// MARK: - Page model


enum SubPage: Equatable{
	case login
	case servers
	case scan
	case music
	case appIcon
	case web(String)
	case none
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
		case .markRead:
			String(localized: "全部已读")
		case .lastHour:
			String(localized: "一小时前")
		case .lastDay:
			String(localized: "一天前")
		case .lastWeek:
			String(localized: "一周前")
		case .lastMonth:
			String(localized: "一月前")
		case .allTime:
			String(localized: "所有时间")
		case .cancel:
			String(localized: "取消")
		}
	}
	
	var date:Date{

		switch self {
		case .lastHour:
			Date().someHourBefore(1)
		case .lastDay:
			Date().someDayBefore(0)
		case .lastWeek:
			Date().someDayBefore(7)
		case .lastMonth:
			Date().someDayBefore(30)
		case .allTime:
			Date()
		default:
			Date().s1970
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
	var key:String
	var status:Bool = false
	
	var name:String{
		var name = url
		if let range = url.range(of: "://") {
		   name.removeSubrange(url.startIndex..<range.upperBound)
		}
		return name
	}
	
	var color: Color{
		status ? .green : .orange
	}
	
	enum CodingKeys: CodingKey {
		case id
		case url
		case key
		case status
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(String.self, forKey: .id)
		self.url = try container.decode(String.self, forKey: .url)
		self.key = try container.decode(String.self, forKey: .key)
		self.status = try container.decode(Bool.self, forKey: .status)
	}
	
	init(id:String = UUID().uuidString, url:String, key: String = "", statues:Bool = false){
		self.id = id
		self.url = url
		self.key = key
		self.status = statues
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

struct CryptoModel: Equatable{
	
	var algorithm: CryptoAlgorithm
	var mode: CryptoMode
	var key: String
	var iv: String
	
	static let data = CryptoModel(algorithm: .AES256, mode: .GCM, key: generateRandomString(32), iv: generateRandomString())
	
	
	static func generateRandomString(_ length: Int = 16) -> String {
		// 创建可用字符集（大写、小写字母和数字）
		let charactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
		
		return String(Array(1...length).compactMap { _ in charactersArray.randomElement() })
	}
	
}

extension CryptoModel: Codable{
	enum CodingKeys: String, CodingKey{
		case algorithm
		case mode
		case key
		case iv
	}
	
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeIfPresent(algorithm, forKey: .algorithm)
		try container.encodeIfPresent(mode, forKey: .mode)
		try container.encodeIfPresent(key, forKey: .key)
		try container.encodeIfPresent(iv, forKey: .iv)
	}

	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.algorithm = try container.decode(CryptoAlgorithm.self, forKey: .algorithm)
		self.mode = try container.decode(CryptoMode.self, forKey: .mode)
		self.key = try container.decode(String.self, forKey: .key)
		self.iv = try container.decode(String.self, forKey: .iv)
	}
	
}

extension CryptoModel: RawRepresentable{
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8) ,
			  let result = try? JSONDecoder().decode(
				Self.self,from: data) else{
			return nil
		}
		self = result
	}

	public var rawValue: String {
		guard let result = try? JSONEncoder().encode(self),
			  let string = String(data: result, encoding: .utf8) else{
			return ""
		}
		return string
	}
	
}

extension CryptoModel: Defaults.Serializable {}


// MARK: - AppIconMode

enum AppIconEnum:String, CaseIterable,Equatable,Defaults.Serializable{
	case def = "AppIcon"
	case zero = "AppIcon0"
	case one = "AppIcon1"
	case two = "AppIcon2"
	
	var logo: String{
		switch self {
		case .def:
			return "logo"
		case .zero:
			return "logo0"
		case .one:
			return "logo1"
		case .two:
			return "logo2"
		}
	}
}

// MARK: - PushExampleModel

struct PushExampleModel:Identifiable {
	var id = UUID().uuidString
	var header,footer: AnyView
	var title,params:String
	var index:Int
}

// MARK: - exportJsonData

struct exportJsonData:Identifiable{
	var id:UUID = UUID()
	var url:URL
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
		case .no:
			String(localized: "不保存")
		case .oneDay:
			String(localized:"1天")
		case .weekDay:
			String(localized:"1周")
		case .month:
			String(localized:"1月")
		case .forever:
			String(localized: "长期")
		}
	}
	
	
}

// MARK: - ImageCacheModel



struct ImageModel: Codable, Identifiable, Defaults.Serializable, Equatable{
	var id:String = UUID().uuidString
	var createDate:Date = Date()
	var url:String
	var another:String?
}


// MARK: - RingTongType

enum RingTongType: Codable{
	case local
	case custom
	case cloud
}

struct SoundDefault: Codable, Defaults.Serializable{
	var type:RingTongType
	var name:String
	static let def = SoundDefault(type: .local, name: "silence")
}




enum DefaultBrowserModel: String, CaseIterable, Defaults.Serializable {
	case safari
	case app

	var title:String{
		switch self {
			case .safari:
				"Safari"
			case .app:
				String(localized: "内部")
		}
	}

}


enum CacheSizeLimit: Int, CaseIterable, Defaults.Serializable {
	case five = 5
	case twenty = 20
	case fifty = 50
	case infinity = 2050

	var title:String{
		switch self {
			case .five:
				"5GB"
			case .twenty:
				"20GB"
			case .fifty:
				"50GB"
			case .infinity:
				"∞"
		}
	}

	var size:Int64{
		Int64(rawValue << 30)
	}
}

