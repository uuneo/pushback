//
//  enum.swift
//  pushme
//
//  Created by lynn on 2025/7/30.
//

import Foundation
import Defaults
import SwiftUI

enum TalkieState {
    case idle
    case recording
    case playing
    
    
    var title:String{
        switch self {
        case .idle:
            String(localized: "空闲中")
        case .recording:
            String(localized: "正在说话...")
        case .playing:
            String(localized: "正在播放...")
        }
    }
    
}

//enum TalkType {
//    case ready
//    case close
//    case space
//    case listen
//    case play
//    case cancel
//
//    
//    
//    var title:String{
//        switch self {
//        case .space:
//            String(localized: "空闲中")
//        case .listen:
//            String(localized: "正在说话...")
//        case .play:
//            String(localized: "正在播放...")
//        case .ready:
//            String(localized: "准备中...")
//        case .cancel:
//            String(localized: "取消发送")
//        case .close:
//            String(localized: "未启动监听")
//
//        }
//    }
//    
//    var color:Color{
//        switch self {
//        case .ready:
//                .orange
//        case .close:
//                .clear
//        case .space:
//                .clear
//        case .listen:
//                .green
//        case .play:
//                .clear
//        case .cancel:
//            .red
//        }
//    }
//}




enum TalkButtonType: String, CaseIterable{
    case prefix
    case suffix
    case call
    case password
}

struct PTTChannel:Identifiable,Equatable, Codable, Defaults.Serializable{
    var id:String = UUID().uuidString
    var timestamp:Date = .now
    var prefix:Int = 50
    var suffix:Int = 1
    var password:String = ""
    var server:PushServerModel? = nil
    var isActive:Bool = false
    
    static func ==(lhs: PTTChannel, rhs: PTTChannel) -> Bool {
        return lhs.prefix == rhs.prefix &&
        lhs.suffix == rhs.suffix &&
        lhs.password == rhs.password
    }
    
    func fileName(userID: String) -> String{
        let bb = Int64(Date().timeIntervalSince1970 * 1000)
        
        return  hex() + "-" + userID + "-" + String(bb, radix: 32) + ".ogg"
    }
    
    func filePath(userID: String) -> URL?{
        BaseConfig.getPTTDirectory()?.appendingPathComponent(fileName(userID: userID))
    }
    
    func hex() -> String{
        return (String(prefix, radix: 32) + "-" +
        String(suffix, radix: 32) + "-" +
        String( Int(password) ?? 0, radix: 32)).uppercased()
    }
    
    static func decimal(hexString: String) -> Self?{
        let parts = hexString.lowercased().split(separator: "-")
        guard parts.count == 3,
              let prefix = Int(parts[0], radix: 32),
              let suffix = Int(parts[1], radix: 32),
              let passwordInt = Int(parts[2], radix: 32) else { return nil }
        var data = Self()
        data.prefix = prefix
        data.suffix = suffix
        if passwordInt > 9999 {
            data.password = String(passwordInt)
        }
        return data
        
    }
    
}


extension Defaults.Keys{
    static let pttChannel = Key<PTTChannel>("pushTalkInteger", default: PTTChannel())
    static let pttHisChannel = Key<[PTTChannel]>("pttHisChannels", default: [])
    static let pttVibration = Key<Bool>("pttVibration", default: true)
    static let pttMusicPlay = Key<Bool>("pttMusicPlay", default: true)
    static let pttNoiseEngine = Key<Bool>("pttNoiseEngine", default: false)
    static let pttVoiceVolume = Key<CGFloat>("pttVoiceVolume", default: 0.5)
    
    static let pttToken = Key<String>("pttToken", default: "")
}


extension [PTTChannel]{
    mutating func set(_ data: PTTChannel){
        var data = data
        if let index = self.firstIndex(of: data){
            self[index].timestamp = .now
        }else{
            data.id = UUID().uuidString
            data.timestamp = .now
            self.insert(data, at: 0)
        }
    }
    
    mutating func setActive(_ data: PTTChannel? = nil){
        for item in self{
            if let index = self.firstIndex(of: item){
                if item == data{
                    self[index].timestamp = .now
                    self[index].isActive = true
                }else{
                    self[index].isActive = false
                }
            }
        }
    }
}
