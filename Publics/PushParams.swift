//
//  PushParams.swift
//  pushback
//
//  Created by lynn on 2025/3/31.
//

import UserNotifications

enum Params: String, CaseIterable{
    case ciphertext
    case ttl
    case title
    case subtitle
    case body
    case icon
    case image
    case from
    case host
    case group
    case sound
    case badge
    case call
    case mode
    case url
    case iv
    case aps
    case alert
    case caf
    case autocopy
    case copy
    case calstartdate
    case calenddate
    case caltitle
    case calcolor
    case calminutes
    case id
    case category
    case level
    case volume
    
    case callback
    
    case widget

    var name:String{ self.rawValue }

    
}


extension [AnyHashable : Any]{
    func raw<T:Any>(_ params: Params)-> T?{
        switch params {
        case .title,.subtitle, .body:
            let alert = (self[Params.aps.name] as? [String: Any])?[Params.alert.name] as? [String: Any]
            return alert?[params.name] as? T
        case .sound:
            return (self[Params.aps.name] as? [AnyHashable: Any])?[Params.sound.name] as? T
        default:
            return self[params.name] as? T
        }
    }
    
    func voiceText() -> String{
        var text:[String] = []
        
        if let title:String = self.raw(Params.title){
            text.append(title)
        }
        
        if let subtitle:String = self.raw(Params.subtitle){
            text.append(subtitle)
        }
        
        if let body:String = self.raw(Params.body){
            text.append(PBMarkdown.plain(body))
        }
        
        return text.joined(separator: ",")
    }
}

