//
//  MessageData.swift
//  pushback
//
//  Created by lynn on 2025/4/25.
//

import SwiftUI
import RealmSwift

class GroupMessagesModel:ObservableObject{
    
    @Published var messages:[Message] = []
    @Published var isLoading:Bool = true
    
    var deleteIds:[String:Bool] = [:]
    
    private var notificationToken:NotificationToken?
    
    
    init(){
        let realm = try! Realm()
        notificationToken = realm.objects(Message.self).sorted(by: \.createDate, ascending: false).observe{ changes in
            debugPrint("正在更新")
            self.isLoading = true
            switch changes {
            case .initial(let results):
                self.messages = Array(results.distinct(by: ["group"]).filter({!(self.deleteIds[$0.id.uuidString] ?? false)}))
            case .update(let results, _, _, _):
                
                self.messages = Array(results.distinct(by: ["group"]).filter({!(self.deleteIds[$0.id.uuidString] ?? false)}))
            case .error(let error):
                print("监听失败: \(error)")
            }
            self.isLoading = false
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

