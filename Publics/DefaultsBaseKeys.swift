//
//  DefaultsConfig.swift
//  pushback
//
//  Created by lynn on 2025/5/9.
//

@_exported import Defaults
import Foundation

let DEFAULTSTORE = UserDefaults(suiteName: BaseConfig.groupName)!

extension Defaults.Key{
    convenience init(_ name: String, _ defaultValue: Value, iCloud: Bool = false){
        self.init(name, default: defaultValue, suite: DEFAULTSTORE, iCloud: iCloud)
    }
}

extension Defaults.Keys{
    
    
    static let deviceToken = Key<String>("deviceToken", "")
    static let voipDeviceToken = Key<String>("voipDeviceToken", "")
    static let firstStart = Key<Bool>("firstStartApp", true)
    static let autoSaveToAlbum = Key<Bool>("autoSaveImageToPhotoAlbum", false)
    static let sound = Key<String>("defaultSound", "xiu")
    static let showGroup = Key<Bool>("showGroupMessage", false)
    static let historyMessageCount = Key<Int>("historyMessageCount", 10)
    static let freeCloudImageCount = Key<Int>("freeCloudImageCount", 30)
    static let muteSetting = Key<[String: Date]>("muteSetting",[:])
    
    static let imageSaves = Key<[String]>("muteSetting", [])
    static let showMessageAvatar = Key<Bool>("showMessageAvatar",false)
    static let id = Key<String>("UserDeviceUniqueId", "")
    static let lang = Key<String>("LocalePreferredLanguagesFirst","")
    static let voicesAutoSpeak = Key<Bool>("voicesAutoSpeak", false)
    static let voicesViewShow = Key<Bool>("voicesViewShow", true)
    static let allMessagecount = Key<Int>("allMessagecount", 0, iCloud: true)
    static let widgetURL = Key<String>("widgetURL", "")
    
}


