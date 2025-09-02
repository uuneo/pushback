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

    static let appSymbol = "NoWords"
    static let groupName = "group.pushback"
    static let icloudName = "iCloud.pushback"

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
        ?? Self.appSymbol
    }
    
    static var testData:String{
        "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"
    }
    
    
    enum FolderType: String, CaseIterable{
        case voice
        case ptt
        case icon
        case image
        case sounds = "Library/Sounds"
        
        var name:String{  self.rawValue }
        
        var path: URL{  BaseConfig.getDir(self)! }
        
        func all(files: Bool = false) -> [URL] {
            if files {
                Self.allCases.reduce(into: [URL]()) { partialResult, data in
                    partialResult = partialResult + data.files()
                }
            } else {
                Self.allCases.compactMap {  $0.path }
            }
        }
        
        func files() -> [URL]{
            BaseConfig.files(in: self.path)
        }
    }
    
    
    // Get the directory to store images in the App Group
    class func getDir(_ name:FolderType) -> URL? {
        guard let containerURL = CONTAINER else { return nil }
        
        let voicesDirectory = containerURL.appendingPathComponent(name.rawValue)
        
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
    
    class func files(in folder: URL) -> [URL] {
        
        guard let containerURL = CONTAINER else { return [] }

        do {
            let items = try FileManager.default.contentsOfDirectory(at: containerURL,
                                                            includingPropertiesForKeys: [.isDirectoryKey],
                                                            options: [.skipsHiddenFiles])
            return items.filter {
                (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == false
            }
        } catch {
            print("Error: \(error)")
            return []
        }
        
    }
    
    static  func deviceInfoString() -> String {
        let deviceName = UIDevice.current.localizedModel
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        
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


