//
//  BaseConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

let ISPAD = UIDevice.current.userInterfaceIdiom == .pad

let CONTAINER =  FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)

class BaseConfig {

    static let appSymbol = "Domogo"
    static let groupName = "group.pushback"
    static let icloudName = "iCloud.pushback"
    static let sounds = "Library/Sounds"
    static let signKey = "com.uuneo.pushback.xxxxxxxxxxxxxxxxxxxxxx"
#if DEBUG
    static let defaultServer = "https://dev.uuneo.com"
#else
    static let defaultServer = "https://uuneo.com"
#endif

    static let docServer = "https://docs.uuneo.com"
    static let defaultImage = docServer + "/_media/avatar.jpg"
    static let problemWebUrl = docServer + "/#/faq"
    static let delpoydoc = docServer + "/#/?id=pushback"
    static let emailHelpUrl = docServer + "/#/email"
    static let helpRegisterWebUrl = docServer + "/#/registerUser"
    static let callback = defaultServer + "/callback"
    static let iconRemote = docServer + "/_media/avatar.png"
    static let privacyURL = docServer + String(localized: "/#/policy")
    static let longSoundPrefix = "pb.sounds.30s"
    static let userAgreement = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

    
    static var AppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Domogo"
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
        
        let voicesDirectory = containerURL.appendingPathComponent("Voice")
        
        // If the directory doesn't exist, create it
        if !FileManager.default.fileExists(atPath: voicesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: voicesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.error("Failed to create images directory: \(error.localizedDescription)")
                return nil
            }
        }
        return voicesDirectory
    }
    
    class func getPTTDirectory() -> URL?{
        guard let containerURL = CONTAINER else { return nil }
        
        let imagesDirectory = containerURL.appendingPathComponent("PUshToTalk")
        
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
    
    static func isVoip() -> Int{
        let version = ProcessInfo.processInfo.operatingSystemVersion
        if version.majorVersion >= 17{
            if version.majorVersion > 17{
                return 1
            }
            if version.majorVersion == 17 && version.minorVersion >= 4{
                return 1
            }
        }
        return 0
        
    }
    
    static func documentUrl(_ fileName: String, fileType: UTType = .image) -> URL?{
        do{
            let filePaeh =  try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return filePaeh.appendingPathComponent(fileName, conformingTo: fileType)
        }catch{
            Log.error(error.localizedDescription)
            return nil
        }
        
    }
}
