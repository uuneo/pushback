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
    
    static func createOrUpdate(id: UUID, group: String, title: String? = nil,
                       subtitle: String? = nil, body: String? = nil, icon: String? = nil,
                       url: String? = nil, image: String? = nil, from: String? = nil, host: String? = nil,
                       level: Int? = nil, ttl: Int, read: Bool = false) throws {
        
        let proxy = try Realm()
        
        
        let groups = proxy.objects(Message.self).filter("group == %@ AND isLatestInGroup == true", group)
        
        try proxy.write {
            groups.setValue(false, forKey: "isLatestInGroup")
        }
        
        
        if let message = proxy.objects(Message.self).filter({$0.id == id}).first{
           try proxy.write {
               message.group = group
               message.createDate = .now
               message.isLatestInGroup = true
               message.title = title
               message.subtitle = subtitle
               message.body = body
               message.icon = icon
               message.url = url
               message.image = image
               message.from = from
               message.host = host
               message.level = level ?? 1
               message.ttl = ttl
               message.read = read
           }
        }
    
        let message = Message()
        message.id = id
        message.group = group
        message.isLatestInGroup = true
        message.title = title
        message.subtitle = subtitle
        message.body = body
        message.icon = icon
        message.url = url
        message.image = image
        message.from = from
        message.host = host
        message.level = level ?? 1
        message.ttl = ttl
        message.read = read
        
        try proxy.write {
            proxy.add(message)
        }
    }
   
    
}
