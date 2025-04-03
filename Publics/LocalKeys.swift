//
//  LocalKeys.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
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
    static let cryptoConfig = Key<CryptoModel>("CryptoSettingFields", CryptoModel.data)
    static let badgeMode = Key<BadgeAutoMode>("Meowbadgemode", .auto)
    static let sound = Key<SoundModel>("defaultSound", SoundModel.def)
    static let appIcon = Key<AppIconEnum>("setting_active_app_icon", .pushback)
    static let messageExpiration = Key<ExpirationTime>("messageExpirtionTime", .forever)
    static let defaultBrowser = Key<DefaultBrowserModel>("defaultBrowserOpen", .safari)
    static let cacheSize = Key<CacheSizeLimit>("CacheSizeLimit", .infinity)
    static let imageSaveDays = Key<ExpirationTime>("imageSaveDays", .forever)
    static let updateDeleteDatabase = Key<Bool>("updateDeleteDatabase", false)
    static let showGroup = Key<Bool>("showGroupMessage", true)
    static let assistantAccouns = Key<[AssistantAccount]>("AssistantAccount",[])
    static let historyMessageCount = Key<Int>("historyMessageCount", 10)
    static let historyMessageBool = Key<Bool>("historyMessageBool", false)
    static let showCodeViewColor = Key<Bool>("showCodeViewColor", true)
    static let freeCloudImageCount = Key<Int>("freeCloudImageCount", 30)
    static let muteSetting = Key<[String: Date]>("muteSetting",[:])
    static let imageSaves = Key<[String]>("muteSetting", [])
    static let showMessageAvatar = Key<Bool>("showMessageAvatar",false)
    static let showAssistant = Key<Bool>("showAssistant",false)
}


public class Log {
    
    /// 日志级别
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case error = "ERROR"
    }
    
    /// 日志输出函数类型
    typealias LogOutput = (String) -> Void
    
    /// 默认日志输出函数（打印到控制台）
    private static var logOutput: LogOutput = { message in
#if DEBUG
        debugPrint(message)
#endif
    }
    
    /// 设置自定义日志输出函数
    static func setLogOutput(_ output: @escaping LogOutput) {
        logOutput = output
    }
    
    /// 基础日志方法
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志消息
    ///   - file: 调用日志的文件名（自动捕获）
    ///   - function: 调用日志的函数名（自动捕获）
    ///   - line: 调用日志的行号（自动捕获）
    private class func base(level: Level, file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
        let fileName = (file as NSString).lastPathComponent // 提取文件名
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) \(function) -> \(message.compactMap { "\($0)" }.joined(separator: ", "))"
        logOutput(logMessage) // 使用配置的日志输出函数
    }
    
    /// 打印调试日志
    class func debug(file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
        base(level: .debug, file: file, function: function, line: line, message)
    }
    
    /// 打印信息日志
    class func info(file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
        base(level: .info, file: file, function: function, line: line, message)
    }
    
    /// 打印错误日志
    class func error(file: String = #file, function: String = #function, line: Int = #line, _ message: Any...) {
        base(level: .error, file: file, function: function, line: line, message)
    }
}
