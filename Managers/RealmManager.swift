//
//  RealmProxy.swift
//  pushback
//
//  Created by uuneo 2024/10/9.
//
import RealmSwift


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

    
}
