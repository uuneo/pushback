//
//  OtherModel.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import SwiftUI
import Defaults
import Foundation



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



// MARK: - MessageAction model

enum MessageAction: String, CaseIterable, Equatable{
	case lastHour = "hourAgo"
	case lastDay = "dayAgo"
	case lastWeek = "weekAgo"
	case lastMonth = "monthAgo"
	case allTime = "allTime"
	case cancel = "cancel"
	
	var localized:String{
		switch self {
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

enum QuickAction: String{
    
    case assistant
    case alldelread
    
	static var selectAction:UIApplicationShortcutItem?

	static var allShortcutItems = [
        
        UIApplicationShortcutItem(
            type: Self.assistant.rawValue,
            localizedTitle: String(localized:  "问智能助手"),
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "message.and.waveform"),
            userInfo: ["name":"assistant" as NSSecureCoding]
        ),

		UIApplicationShortcutItem(
            type: Self.alldelread.rawValue,
			localizedTitle: String(localized: "删除全部已读"),
			localizedSubtitle: "",
			icon: UIApplicationShortcutIcon(systemImageName: "trash"),
			userInfo: ["name":"alldelread" as NSSecureCoding]
		)
		
	]
}

// MARK: - PushServerModel

struct PushServerModel: Codable, Identifiable,Equatable, Hashable{
	var id:String = UUID().uuidString
    var device:String
	var url:String
	var key:String = ""
	var status:Bool = false
	var createDate:Date = .now
	var updateDate:Date = .now
    
    init(id: String = UUID().uuidString, device: String? = nil, url: String, key: String = "", status: Bool = false, createDate: Date = .now, updateDate: Date = .now) {
        self.id = id
        self.device = device ?? BaseConfig.deviceInfoString()
        self.url = url
        self.key = key
        self.status = status
        self.createDate = createDate
        self.updateDate = updateDate
    }

	var name:String{
		var name = url
		if let range = url.range(of: "://") {
		   name.removeSubrange(url.startIndex..<range.upperBound)
		}
		return name
	}
	
	var color: Color{ status ? .green : .orange }
    var server:String{
        return self.url + "/" + self.key
    }
}

// MARK: - BadgeAutoMode

enum BadgeAutoMode:String, CaseIterable {
	case auto = "Auto"
	case custom = "Custom"
}

// MARK: - CryptoMode

enum CryptoMode: String, Codable,CaseIterable, RawRepresentable {
	
	case CBC, ECB, GCM
	var padding: String {
		self == .GCM ? "Space" : "PKCS7"
	}

	
}

enum CryptoAlgorithm: Int, Codable, CaseIterable,RawRepresentable {
	case AES128 = 16 // 16 bytes = 128 bits
	case AES192 = 24 // 24 bytes = 192 bits
	case AES256 = 32 // 32 bytes = 256 bits
	
	var name:String{
		self == .AES128 ? "AES128" : (self == .AES192 ? "AES192" : "AES256")
	}
}


struct CryptoModelConfig: Equatable, Codable{

	var algorithm: CryptoAlgorithm
	var mode: CryptoMode
	var key: String
	var iv: String

	static let data = CryptoModelConfig(algorithm: .AES256, mode: .GCM, key: "KXkwFRs2ttGJi7mJdJk9AsjAF4jbr135", iv: "xBCSyAxsjkdrjFCa")

	static func generateRandomString(_ length: Int = 16) -> String {
		// 创建可用字符集（大写、小写字母和数字）
		let charactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
		
		return String(Array(1...length).compactMap { _ in charactersArray.randomElement() })
	}
	
}

extension CryptoModelConfig {
    func obfuscator() -> String? {
        
        guard iv.count == 16, key.count >= 16, mode.rawValue.count == 3 else { return nil }
        
        let position: (Int, Int, Int) = CryptoModelConfig.calculateInsertPositions(for: iv + key + mode.rawValue)

        var result = iv + key
        let inserts = Array(mode.rawValue.lowercased())
        let positions = [position.0, position.1, position.2].sorted()

        // 从后往前插入，防止位置错乱
        for i in (0..<3).reversed() {
            let idx = result.index(result.startIndex, offsetBy: positions[i])
            result.insert(inserts[i], at: idx)
        }

        return String(result.reversed())
    }

    static func deobfuscator(result: String) -> CryptoModelConfig? {
        
        let result = String(result.reversed())
        guard result.count > 20 else { return nil}
        
        let position: (Int, Int, Int) = CryptoModelConfig.calculateInsertPositions(for: result)
        
        var original = result
        let positions = [position.0, position.1, position.2].sorted()
        var inserts = ""
        
        // 从前往后移除字符（位置会因为删除而变化）
        for i in 0..<3 {
            let index = original.index(original.startIndex, offsetBy: positions[i])
            inserts.append(original[index])
            original.remove(at: index)
        }
        let startIndex = original.startIndex
        let splitIndex = original.index(startIndex, offsetBy: 16)
        
        let ivData = String(original[startIndex..<splitIndex])
        let keyData = String(original[splitIndex...])
        inserts = inserts.uppercased()
        if let mode = CryptoMode(rawValue: inserts), let algorithm = CryptoAlgorithm(rawValue: keyData.count){
           return CryptoModelConfig(algorithm: algorithm, mode: mode, key: keyData, iv: ivData)
        }
        return nil
      
    }


    static func calculateInsertPositions(for string: String) -> (Int, Int, Int) {
        let hashValue = string.count - 3
        let pos1 = abs(hashValue / 3 + 1)
        let pos2 = abs(hashValue / 2 - 2)
        let pos3 = abs(hashValue - pos1)
        return (pos1, pos2, pos3)
    }

}


// MARK: - AppIconMode

enum AppIconEnum:String, CaseIterable,Equatable{
    case king
	case pushback
    case bell
    case Whale
    
    
    var name: String? { self == .pushback ? nil : self.rawValue }
    
    var logo: String{
        switch self {
        case .pushback:
            return "logo"
        case .bell:
            return "logo1"
        case .Whale:
            return "logo2"
        case .king:
            return "logo3"
        }
    }
}

// MARK: - PushExampleModel

struct PushExampleModel:Identifiable {
	var id = UUID().uuidString
	var header,footer: AnyView
    var title:String
	var params:String
	var index:Int
}



// MARK: - ExpirationTime

enum DefaultBrowserModel: String, CaseIterable {
	case safari
	case app

	var title:String{
		switch self {
			case .safari: "Safari"
			case .app: String(localized: "内部")
		}
	}

}


struct AssistantAccount: Codable, Identifiable, Equatable,Hashable{
    var id:String = UUID().uuidString
    var current:Bool = false
    var timestamp:Date = .now
    var name:String = String(localized: "智能助手")
    var host:String
    var basePath:String
    var key:String
    var model:String
    
    func toBase64() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }
    
    init( current: Bool = false, name: String = String(localized: "智能助手"), host: String, basePath: String, key: String, model: String) {
        self.current = current
        self.name = name
        self.host = host
        self.basePath = basePath
        self.key = key
        self.model = model
    }
    
    
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64), let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = decoded
        self.id = UUID().uuidString
    }
    
    
    

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



enum CategoryParams: String, Codable, CaseIterable{
    case myNotificationCategory
    case markdown
    
    var name:String{
        switch self {
        case .myNotificationCategory:
            return String(localized: "普通内容")
        case .markdown:
            return String(localized: "Markdown")
        }
    }
}

enum OutDataType{
    case text(String)
    case crypto(String)
    case server(String)
    case serverKey(url:String,key:String)
    case otherUrl(String)
    case assistant(String)
    case page(page:pageType, title:String?, data:String)
    
    enum pageType: String {
        case widget
        case icon
    }
}


enum ExpirationTime: Int, CaseIterable, Equatable{
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


struct SelectMessage: Codable{
    
    var id:UUID = UUID()
    var group:String
    var createDate:Date
    var title:String?
    var subtitle:String?
    var body:String?
    var icon:String?
    var url:String?
    var image:String?
    var from:String?
    var host:String?
    var level:Int = 1
    var ttl:Int = ExpirationTime.forever.days
    var read:Bool = false
    var search:String

}


// MARK: - Page model
enum SubPage: Equatable{
    case customKey
    case scan
    case appIcon
    case web(String)
    case cloudIcon
    case paywall
    case quickResponseCode(text:String,title: String?,preview: String?)
    case none
    
}

enum RouterPage: Hashable {
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto(String?)
    case server
    case assistantSetting(AssistantAccount?)
    case privacy
    case more
    
    case widget(title:String?, data:String)
    
    case tts
}

enum TabPage :String{
    case message
    case setting
}

enum outRouterPage: String{
    case widget
    case icon
}

enum PBScheme: String, CaseIterable{
    case pb
    case mw
    static var schemes:[String]{ Self.allCases.compactMap({ $0.rawValue }) }
    
    enum HostType: String{
        case server
        case crypto
        case assistant
        case openPage
        case widget
    }
    
    // pb://openpage?title=string or mw://openpage?title=string
    func scheme(host: HostType, params parameters: [String: Any]) -> URL {
        var components = URLComponents()
        components.scheme = self.rawValue
        components.host = host.rawValue // 固定 host，如果有 path 也可以加上
        
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        
        return components.url!
    }
    
}
