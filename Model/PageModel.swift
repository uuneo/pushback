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
        case let (.call(a), .call(b)):
            return a == b
        case let (.answer(a), .answer(b)):
            return a == b
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
    case none
    
    case call(String)
    case answer(CallUser)
    
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
    case call
    case widget(title:String?, data:String)
    case deviceInfo
    case tts
}

enum TabPage :String, Sendable{
    case message
    case setting
}

enum outRouterPage: String{
    case widget
    case icon
}
