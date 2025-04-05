//
//  BaseConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/25.
//

import Foundation
import UIKit

let DEFAULTSTORE = UserDefaults(suiteName: BaseConfig.groupName)!
let ISPAD = UIDevice.current.userInterfaceIdiom == .pad

class BaseConfig {
	
	static let  groupName = "group.pushback"
	static let 	icloudName = "iCloud.pushback"
	static let  realmName = "Meowrld.realm"
	static let  sounds = "Library/Sounds"
	static let	signKey = "com.uuneo.pushback.xxxxxxxxxxxxxxxxxxxxxx"
	static let 	cacheSizeLimit = "CacheSizeLimit"
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
	static let testData = "{\"title\": \"\(String(localized: "这是一个加密示例"))\",\"body\": \"\(String(localized: "这是加密的正文部分"))\", \"sound\": \"typewriter\"}"

    static let imageIcloudKey = "uploadImageForcloud.png"
    
    
  
	
	/// 获取共享目录下的 Sounds 文件夹，如果不存在就创建
	class func getSoundsGroupDirectory() -> URL? {
		let manager = FileManager.default
		if let directoryUrl = manager.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)?.appendingPathComponent(BaseConfig.sounds) {
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
		guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName) else {
			return nil
		}
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

}
