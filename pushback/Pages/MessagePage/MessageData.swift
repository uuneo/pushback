//
//  MessageData.swift
//  pushback
//
//  Created by lynn on 2025/4/25.
//

import SwiftUI
import RealmSwift

class MessagesData:ObservableObject{
    
    static let shared = MessagesData()
    
    @Published var messages:[Message] = []
    @Published var isLoading:Bool = true
    @Published var unReadCount:Int = 0
    @Published var allCount:Int = 0
    
    var deleteIds:[String:Bool] = [:]
    
    private var notificationToken:NotificationToken?
    
    private init(){
        let realm = try! Realm()
        notificationToken = realm.objects(Message.self).sorted(by: \.createDate, ascending: false).observe{ changes in
            debugPrint("正在更新")
            self.isLoading = true
            switch changes {
            case .initial(let results):
                self.update(results: results)
            case .update(let results, _, _, _):
                self.update(results: results)
            case .error(let error):
                print("监听失败: \(error)")
            }
            self.isLoading = false
        }
    }
    
    func update(results:Results<Message>){
        let messages = Array(results.distinct(by: ["group"]).filter({!(self.deleteIds[$0.id.uuidString] ?? false)}))
        let unReadCount = results.filter({!$0.read}).count
        let allCount = results.count
        DispatchQueue.main.async {
            self.messages = messages
            self.unReadCount = unReadCount
            self.allCount = allCount
        }
    }
    
    deinit{
        notificationToken?.invalidate()
    }
    
    func delete(message: Message){
        let (id, group) = (message.id, message.group)
        
        deleteIds[id.uuidString] = true
        
        self.messages.removeAll(where: {$0.id == id})
        
        Task.detached {
            let realm = try Realm()
            try autoreleasepool {
                let messages = realm.objects(Message.self).where({$0.group == group})
                try realm.write {
                    realm.delete(messages)
                }
            }
        }
    }
}

