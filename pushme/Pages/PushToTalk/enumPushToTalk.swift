//
//  enum.swift
//  pushme
//
//  Created by lynn on 2025/7/30.
//

import Foundation
import Defaults
import SwiftUI

enum TalkType {
    case ready
    case close
    case space
    case listen
    case play
    case cancel

    
    
    var title:String{
        switch self {
        case .space:
            String(localized: "空闲中")
        case .listen:
            String(localized: "正在说话...")
        case .play:
            String(localized: "正在播放...")
        case .ready:
            String(localized: "准备中...")
        case .cancel:
            String(localized: "取消发送")
        case .close:
            String(localized: "未启动监听")

        }
    }
    
    var color:Color{
        switch self {
        case .ready:
                .orange
        case .close:
                .clear
        case .space:
                .clear
        case .listen:
                .green
        case .play:
                .clear
        case .cancel:
            .red
        }
    }
}




enum TalkButtonType: String, CaseIterable{
    case prefix
    case suffix
    case call
}

struct TalkChannel: Codable, Defaults.Serializable{
    var id:String = UUID().uuidString
    var prefix:Int = 50
    var suffix:Int = 1
}


extension Defaults.Keys{
    static let talkChannel = Key<TalkChannel>("pushTalkInteger", default: TalkChannel())
}
