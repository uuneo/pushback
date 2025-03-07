//
//  LocalKeys.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

@_exported import Defaults
import Foundation

extension Defaults.Key{
	convenience init(_ name: String, _ defaultValue: Value, iCloud: Bool = false){
		self.init(name, default: defaultValue, suite: DEFAULTSTORE, iCloud: iCloud)
	}
}

extension Defaults.Keys {
	static let deviceToken = Key<String>("deviceToken", "")
	static let firstStart = Key<Bool>("firstStartApp", true)
	static let photoName = Key<String>("CustomPhotoName", "pushback.")
	static let autoSaveToAlbum = Key<Bool>("autoSaveImageToPhotoAlbum", false)
	static let servers = Key<[PushServerModel]>("serverArrayStroage", [])
	static let images = Key<[ImageModel]>("imagesLocalMap",  [])
	static let cryptoConfig = Key<CryptoModel>("CryptoSettingFields", CryptoModel.data)
	static let badgeMode = Key<BadgeAutoMode>("Meowbadgemode", .auto)
	static let sound = Key<SoundModel>("defaultSound", SoundModel.def)
    static let appIcon = Key<AppIconEnum>("setting_active_app_icon", .Whale)
	static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
	static let defaultBrowser = Key<DefaultBrowserModel>("defaultBrowserOpen", .safari)
	static let cacheSize = Key<CacheSizeLimit>("CacheSizeLimit", .infinity)
	static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
	static let updateDeleteDatabase = Key<Bool>("updateDeleteDatabase", false)
    static let showGroup = Key<Bool>("showGroupMessage", false)
    
    static let assistantAccouns = Key<[AssistantAccount]>("AssistantAccount",[])
    static let historyMessageCount = Key<Int>("historyMessageCount", 10)
    static let historyMessageBool = Key<Bool>("historyMessageBool", true)
}

public class Log {
	/// 打印日志
	/// - Parameters:
	///   - mode: 类型
	///   - message: 日志消息
	///   - file: 调用日志的文件名（自动捕获）
	///   - function: 调用日志的函数名（自动捕获）
	///   - line: 调用日志的行号（自动捕获）
	class func base(mode: String, file:String, function: String, line: Int, _ message: Any...) {
		let fileName = (file as NSString).lastPathComponent // 提取文件名

		let logMessage = "[\(mode)] \(fileName):\(line) \(function) ->\n    \(message.compactMap({"\($0)"}).joined(separator: ","))"

		// 控制台打印日志
		print(logMessage)
	}

	class func debug(file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
		self.base(mode: "DEBUG", file: file, function: function, line: line, message)
	}

	class func info(file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
		self.base(mode: "INFO", file: file, function: function, line: line, message)
	}

	class func error( file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
		self.base(mode: "ERROR", file: file, function: function, line: line, message)
	}
}
