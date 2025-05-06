//
//  BaseConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/25.
//

import Foundation
import UIKit

let ISPAD = UIDevice.current.userInterfaceIdiom == .pad

let CONTAINER =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)

class BaseConfig {
	
	static let  groupName = "group.pushback"
	static let 	icloudName = "iCloud.pushback"
	static let  realmName = "Meowrld.realm"
	static let  sounds = "Library/Sounds"
	static let	signKey = "com.uuneo.pushback.xxxxxxxxxxxxxxxxxxxxxx"
#if DEBUG
	static let defaultServer = "https://dev.uuneo.com"
#else
	static let defaultServer = "https://push.uuneo.com"
#endif
	static let docServer = "https://pushback.uuneo.com"
    static let statusServer = "https://status.uuneo.com"
	static let defaultImage = docServer + "/_media/avatar.jpg"
	static let helpWebUrl = docServer + "/#/tutorial"
	static let problemWebUrl = docServer + "/#/faq"
	static let delpoydoc = docServer + "/#/?id=pushback"
	static let emailHelpUrl = docServer + "/#/email"
	static let helpRegisterWebUrl = docServer + "/#/registerUser"
	static let callback = defaultServer + "/callback"
	static let iconRemote = docServer + "/_media/avatar.png"
	static let privacyURL = docServer + String(localized: "/#/policy")
    static let longSoundPrefix = "pb.sounds.30s"
	static let userAgreement = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
	static let musicUrl = "https://convertio.co/mp3-caf/"
    static let imageIcloudKey = "uploadImageForcloud.png"
    
    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Pushback"
    }
    static var testData:String{
        "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"
    }
    
	
	/// 获取共享目录下的 Sounds 文件夹，如果不存在就创建
	class func getSoundsGroupDirectory() -> URL? {
		let manager = FileManager.default
		if let directoryUrl = CONTAINER?.appendingPathComponent(BaseConfig.sounds) {
			if !manager.fileExists(atPath: directoryUrl.path) {
                try? manager.createDirectory(atPath: directoryUrl.path, withIntermediateDirectories: true, attributes: nil)
			}
			return URL(fileURLWithPath: directoryUrl.path)
		}
		return nil
	}
    
    enum ImageMode: String {
        case icon
        case image
        var name:String{  self.rawValue }
    }
   
	// Get the directory to store images in the App Group
    class func getImagesDirectory(mode:ImageMode = .icon) -> URL? {
		guard let containerURL = CONTAINER else { return nil }
        
        let imagesDirectory = containerURL.appendingPathComponent(mode.name)
		
		// If the directory doesn't exist, create it
		if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
			do {
				try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
			} catch {
                Log.error("Failed to create images directory: \(error.localizedDescription)")
				return nil
			}
		}
		return imagesDirectory
	}
    
    // Get the directory to store images in the App Group
    class func getVoiceDirectory() -> URL? {
        guard let containerURL = CONTAINER else { return nil }
        
        let imagesDirectory = containerURL.appendingPathComponent("Voice")
        
        // If the directory doesn't exist, create it
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.error("Failed to create images directory: \(error.localizedDescription)")
                return nil
            }
        }
        return imagesDirectory
    }
    
    
   static  func deviceInfoString() -> String {
       let deviceName = UIDevice.current.localizedModel
        let deviceModel = UIDevice.current.model // "iPhone" 变成 "iphone"
        let systemName = UIDevice.current.systemName // "iOS" 变成 "ios"
        let systemVersion = UIDevice.current.systemVersion // 版本号比如 "18.0.4"
        
        return "\(deviceName) (\(deviceModel)-\(systemName)-\(systemVersion))"
    }
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
