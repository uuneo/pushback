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


class RealmManager{
    
    static let shared = RealmManager()
    private init(){}
    
    
    class func realm(completion: @escaping (Realm) -> Void, fail: ((String)->Void)? = nil){
        do{
            let proxy = try Realm()
            
            try proxy.write {
                completion(proxy)
            }
            
        }catch{
            fail?(error.localizedDescription)
        }
    }

    
}
