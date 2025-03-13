//
//  RealmProxy.swift
//  pushback
//
//  Created by uuneo 2024/10/9.
//
import SwiftUI
import RealmSwift
import Defaults
import SwiftyJSON

@MainActor
class RealmManager{
    
    static let shared = RealmManager()
    private init(){}
    
    
    func realm(completion: @escaping (Realm) -> Void, fail: ((String)->Void)? = nil){
        do{
            let proxy = try Realm()
            
            try proxy.write {
                completion(proxy)
            }
            
        }catch{
            fail?(error.localizedDescription)
        }
    }
    
    
    
    func read(_ read: Bool){
        self.realm { proxy in
            let messages = proxy.objects(Message.self).filter({ (msg) -> Bool in
                msg.read == read
            })
            
            proxy.delete(messages)
            
            RealmManager.ChangeBadge()
        }
        
    }
    
    func read(_ group: String? = nil){
        self.realm { proxy in
            if let group{
                
                for msg in proxy.objects(Message.self).filter({$0.group == group && !$0.read}){
                    msg.read = true
                }
                
            }else{
                for msg in proxy.objects(Message.self).filter({ !$0.read}){
                    msg.read = true
                }
            }
            
            RealmManager.ChangeBadge()
        }
    }
    
    
    func read(_ message:Message ,completion: ((String)-> Void)? = nil) {
        self.realm { proxy in
            if let data = proxy.objects(Message.self).first(where: {$0 == message}){
                data.read = true
                completion?(String(localized: "修改成功"))
                RealmManager.ChangeBadge()
            }else{
                completion?(String(localized: "没有数据"))
            }
        }
        
    }
    
    
    func delete(_ date: Date){
        self.realm { proxy in
            proxy.delete(proxy.objects(Message.self).where({ $0.createDate < date }))
            proxy.deleteAll()
        }
    }
    func deleteAll(){
        self.realm { proxy in proxy.deleteAll() }
    }
    
    func deleteExpired() {
        self.realm { proxy in
            proxy.delete(proxy.objects(Message.self).filter({$0.isExpired()}))
            RealmManager.ChangeBadge()
        }
    }
    
    func delete(group: String){
        self.realm { proxy in
            proxy.delete(proxy.objects(Message.self).filter( {$0.group == group} ))
            RealmManager.ChangeBadge()
        }
    }
    
    
    func delete(_ message:Message ,completion: ((String)-> Void)? = nil){
        
        self.realm { proxy in
            if let data = proxy.objects(Message.self).first(where: {$0 == message}){
                proxy.delete(data)
                completion?(String(localized: "删除成功"))
            }else{
                completion?(String(localized: "没有数据"))
            }
        }
    }
    
    
    func update(_ message:Message ,completion: @escaping (Message?) -> Void){
        self.realm { proxy in
            completion(proxy.objects(Message.self).first(where: {$0 == message}))
        }
    }
    
    
    static func unReadCount() -> Int{
        do {
            let realm  = try Realm()
            return realm.objects(Message.self).filter({ !$0.read }).count
        }catch{
            print(error.localizedDescription)
            return 0
        }
    }
    
    static func ChangeBadge(){
        if Defaults[.badgeMode] == .auto{
            UNUserNotificationCenter.current().setBadgeCount( unReadCount() )
        }
        
    }
    
   
    
   
    
    
   
    
    
    
    
}
