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
    
    func update(_ message:Message ,completion: @escaping (Message?) -> Void){
        self.realm { proxy in
            completion(proxy.objects(Message.self).first(where: {$0 == message}))
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
    
    func importMessage(_ fileUrls: [URL]) -> String {
        do{
            for url in fileUrls{
                
                if url.startAccessingSecurityScopedResource(){
                    
                    let data = try Data(contentsOf: url)
                    
                    guard let arr = try JSON(data: data).array else { return String(localized: "文件格式错误") }
                    
                    self.realm { proxy in
                        for message in arr {
                            
                            guard let id = message["id"].string,let createDate = message["createDate"].int64 else { continue }
                            
                            let messageObject = Message()
                            if let idString = UUID(uuidString: id){ messageObject.id = idString }
                            
                            messageObject.title = message["title"].string
                            messageObject.body = message["body"].string
                            messageObject.url = message["url"].string
                            messageObject.group = message["group"].string ?? String(localized: "导入数据")
                            messageObject.read = true
                            messageObject.level = message["level"].int ?? 1
                            messageObject.image = message["image"].string
                            messageObject.video = message["video"].string
                            messageObject.ttl = ExpirationTime.forever.days
                            messageObject.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
                            messageObject.userInfo = message["userInfo"].string ?? ""
                            
                            proxy.add(messageObject, update: .modified)
                        }
                    }
                    
                }
                
                
                
            }
            
            return String(localized: "导入成功")
            
        }catch{
            Log.debug(error)
            return error.localizedDescription
        }
    }
    
    struct ChatMessageSection {
        var id:String = UUID().uuidString
        var title: String // 分组名称，例如 "[今天]"
        var messages: [ChatGroup]
    }
    
    
    // 获取所有消息并按时间分组
    func getGroupedMessages(allMessages: Results<ChatGroup>) -> [ChatMessageSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)! // 昨天
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)! // 前天
        let twoDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)! // 2天前
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)! // 一周前
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)! // 两周前
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)! // 1月前
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today)! // 3月前
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today)! // 半年前
        
        
        // 按时间分组
        var groupedMessages: [ChatMessageSection] = []
        
        // 今天
        let todayMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= today }
        if !todayMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "今天"), messages: todayMessages))
        }
        
        // 昨天
        let yesterdayMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= yesterday && $0.timestamp < today }
        if !yesterdayMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "昨天"), messages: yesterdayMessages))
        }
        
        // 前天
        let dayBeforeYesterdayMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= dayBeforeYesterday && $0.timestamp < yesterday }
        if !dayBeforeYesterdayMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "前天"), messages: dayBeforeYesterdayMessages))
        }
        
        // 2天前
        let twoDaysAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= twoDaysAgo && $0.timestamp < dayBeforeYesterday }
        if !twoDaysAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "2天前"), messages: twoDaysAgoMessages))
        }
        
        // 一周前
        let oneWeekAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= oneWeekAgo && $0.timestamp < twoDaysAgo }
        if !oneWeekAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "一周前"), messages: oneWeekAgoMessages))
        }
        
        // 两周前
        let twoWeeksAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < oneWeekAgo }
        if !twoWeeksAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "两周前"), messages: twoWeeksAgoMessages))
        }
        
        // 1月前
        let oneMonthAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= oneMonthAgo && $0.timestamp < twoWeeksAgo }
        if !oneMonthAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "1月前"), messages: oneMonthAgoMessages))
        }
        
        // 3月前
        let threeMonthsAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= threeMonthsAgo && $0.timestamp < oneMonthAgo }
        if !threeMonthsAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "3月前"), messages: threeMonthsAgoMessages))
        }
        
        // 半年前
        let sixMonthsAgoMessages: [ChatGroup] = allMessages.filter { $0.timestamp >= sixMonthsAgo && $0.timestamp < threeMonthsAgo }
        if !sixMonthsAgoMessages.isEmpty {
            groupedMessages.append(ChatMessageSection (title: String(localized: "半年前"), messages: sixMonthsAgoMessages))
        }
        
        return groupedMessages
    }
    
    
    
    
    
}
