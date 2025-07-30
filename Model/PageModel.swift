//
//  PageModel.swift
//  pushme
//
//  Created by lynn on 2025/6/18.
//
import Foundation

// MARK: - Page model
enum SubPage: Equatable{
    static func == (lhs: SubPage, rhs: SubPage) -> Bool {
        switch (lhs, rhs) {
        case (.customKey, .customKey),(.scan, .scan),(.appIcon, .appIcon),
            (.cloudIcon, .cloudIcon), (.paywall, .paywall),(.none, .none):
            return true
        case let (.web(a), .web(b)):
            return a == b
        case let (.quickResponseCode(ta, tia, pra), .quickResponseCode(tb, tib, prb)):
            return ta == tb && tia == tib && pra == prb
        default:
            return false
        }
    }
    
    case customKey
    case scan
    case appIcon
    case web(String)
    case cloudIcon
    case paywall
    case quickResponseCode(text:String,title: String?,preview: String?)
    case pushToTalk
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
    case more
    case widget(title:String?, data:String)
    case tts
    case pushtalk
}

enum TabPage: String, Sendable, CaseIterable{
    case message
    case assistant
    case pushtalk
    case setting
    
    var title: String{
        switch self {
        case .message: String(localized: "消息")
        case .assistant: String(localized: "智能助手")
        case .pushtalk: String(localized: "语音信息")
        case .setting: String(localized: "设置")
        }
    }
    
    var symbol: String {
        switch self {
        case .message: 
            return "ellipsis.message"
        case .assistant:
            if #available(iOS 18.0, *){
                return "apple.intelligence"
            }else{
               return "atom"
            }
        case .pushtalk:
            return "speaker.wave.2.bubble.left"
        case .setting:
            return "gear.circle"
        }
    }
    
    var index: Int {  Self.allCases.firstIndex(of: self) ?? 0}
    
    var showSearch:Bool{ self == .message }
    
    var animate: sybolEffectType{
        switch self {
        case .message:
                .variableColor
        case .assistant:
                .rotate
        case .pushtalk:
                .variableColor
        case .setting:
                .rotate
        }
    }
    
    var showTabBar:Bool{
        switch self {
        case .message:
            true
        case .assistant:
            false
        case .pushtalk:
            false
        case .setting:
            true
        }
    }
}

enum outRouterPage: String{
    case widget
    case icon
}
