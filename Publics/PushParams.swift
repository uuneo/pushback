//
//  PushParams.swift
//  pushback
//
//  Created by lynn on 2025/3/31.
//

import UserNotifications

enum Params: String, CaseIterable{
    case ciphertext, ttl, title, subtitle, body, icon, image, from, host, group,
         sound, badge, call, mode, url, iv, aps, alert, caf, autocopy, copy,
         calstartdate, calenddate, caltitle, calcolor, calminutes, ciphernumber,
         id, category, level, volume, callback, widget, savealbum, count, index
    
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
            if T.self == Int.self, let data = self[params.name] as? String, let intValue = Int(data) {
                return intValue as? T
            } else if let intValue = self[params.name] as? Int {
                return intValue as? T
            }
            
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

