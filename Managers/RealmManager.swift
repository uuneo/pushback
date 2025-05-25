//
//  RealmProxy.swift
//  pushback
//
//  Created by uuneo 2024/10/9.
//
import RealmSwift
import Foundation


class RealmManager{
    
    
    static func handler(completion: @escaping (Realm) -> Void, fail: ((String)->Void)? = nil){
        do{
            let proxy = try Realm()
            completion(proxy)
        }catch{
            fail?(error.localizedDescription)
        }
    }
    
    
    static func unRead(_ group:String? = nil) -> Int{
        do{
            let results = try Realm().objects(Message.self).where({!$0.read})
            if let group{
                return results.where({$0.group == group}).count
            }
            return results.count
            
        }catch{
            return 0
        }
        
    }
    
    static func examples() ->[Message]{
        [
            Message(value: ["title":  String(localized: "示例"),"group":  String(localized: "示例"),"body": String(localized:  "点击或者滑动可以修改信息状态"),"mode":"999","ttl": 1]),

            Message(value: ["group":  "App","title":String(localized: "点击跳转app") ,"body":String(localized:  "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),"url":"weixin://","mode":"999","ttl": 1]),
            
            Message(value: ["group":  "Markdown", "title":String(localized: "示例") ,"body":"# Pushback \n## Pushback \n### Pushback", "mode":"999","ttl": 1])
            
        ]
    }
    
}
