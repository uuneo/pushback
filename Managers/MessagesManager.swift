//
//  MessagesManager.swift
//  pushback
//
//  Created by lynn on 2025/5/26.
//
import Foundation
import GRDB

class MessagesManager: ObservableObject{
    static let shared =  MessagesManager()
    
    let local:URL
    let dbQueue:DatabasePool
    private var observationCancellable: AnyDatabaseCancellable?
    
    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 0
    @Published var updateSign:Int = 0
    @Published var groupMessages: [Message] = []
    @Published var showGroupLoading:Bool = false
    
    private init() {
        self.dbQueue = DatabaseManager.shared.dbQueue
        self.local = DatabaseManager.shared.localPath
        try! Message.createInit(dbQueue: dbQueue)
        startObservingUnreadCount()
    }
    
    deinit{
        observationCancellable?.cancel()
    }
    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int,Int) in
            let unRead = try Message
                .filter(Column("read") == false)
                .fetchCount(db)
            let count = try Message
                .fetchCount(db)
            return (unRead,count)
        }
        
        observationCancellable = observation.start(
            in: dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                print("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newUnreadCount in
                print("监听 SqlLite \(newUnreadCount)")
                let results = self?.queryGroup()
                DispatchQueue.main.async {
                    self?.updateSign += 1
                    self?.unreadCount = newUnreadCount.0
                    self?.allCount = newUnreadCount.1
                    self?.showGroupLoading = true
                    if let results{
                        self?.groupMessages = results
                    }
                   
                    self?.showGroupLoading = false
                }
            }
        )
    }
    
}

//  message 消息方法
extension MessagesManager{
    func unreadCount(group: String? = nil)-> Int {
        do{
            return try dbQueue.read { db in
                var request = Message.filter(Column("read") == false)
                
                if let group = group {
                    request = request.filter(Column("group") == group)
                }
    
                return try request.fetchCount(db)
            }
        }catch{
            print("查询失败")
            return 0
        }
        
    }
    
    func count(group: String? = nil)-> Int {
        do{
            let count = try dbQueue.read { db in
                if let group = group{
                    return  try Message.filter(Message.Columns.group == group).fetchCount(db)
                }else {
                    return  try Message.fetchCount(db)
                }
               
            }
            return count
        }catch{
            print(error.localizedDescription)
            return 0
        }
    }
    
    func add(_ message: Message) {
        do {
            try dbQueue.write { db in
                try message.insert(db, onConflict: .replace)
            }
        } catch {
            print("Add or update message failed:", error)
        }
    }
    func query(id: String) -> Message? {
        do {
            return try dbQueue.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            print("Failed to query message by id:", error)
            return nil
        }
    }
    
    func query(search: String, group: String? = nil,
               limit lim: Int = 50, _ date: Date? = nil) -> ([Message],Int) {
        debugPrint(search)
        do {
            return try dbQueue.read { db in
                let escapedQuery = search.replacingOccurrences(of: "%", with: "\\%")
                    .replacingOccurrences(of: "_", with: "\\_")
                let pattern = "%" + escapedQuery + "%"
                
                var request =  Message.filter(
                    Message.Columns.title.like(pattern)
                    || Message.Columns.subtitle.like(pattern)
                    || Message.Columns.body.like(pattern)
                    || Message.Columns.group.like(pattern)
                ).order(Message.Columns.createDate.desc)
                if let group = group{
                    request = request.filter(Message.Columns.group == group)
                }
                
                if let date = date{
                    request = request.filter(Message.Columns.createDate < date)
                }
                
                
                return (try request.limit(lim).fetchAll(db),try request.fetchCount(db))
            }
        } catch {
            print("Query error: \(error)")
            return ([], 0)
        }
    }


    
    func queryGroup() -> [Message] {
        do {
            return try dbQueue.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT m.*
                    FROM message m
                    INNER JOIN (
                        SELECT "group", MAX(createDate) AS maxDate
                        FROM message
                        GROUP BY "group"
                    ) grouped
                    ON m."group" = grouped."group" AND m.createDate = grouped.maxDate
                    ORDER BY m.createDate DESC
                """)
                let messages = try rows.map { try Message(row: $0) }
               
                return messages
            }
        } catch {
            print("Failed to query messages:", error)
            return []
        }
    }
    
    func query(group: String? = nil, limit lim: Int = 50, _ date: Date? = nil) -> [Message] {
        do {
            return try dbQueue.read { db in
                var request = Message.order(Column("createDate").desc)
                
                if let group = group {
                    request = request.filter(Column("group") == group)
                }
                
                if let date = date {
                    request = request.filter(Column("createDate") < date)
                }
                
                return try request.limit(lim).fetchAll(db)
            }
        } catch {
            print("Query failed:", error)
            return []
        }
    }
    
    func markAllRead(group: String? = nil) {
        do{
            try dbQueue.write { db in
                var request = Message.filter(Column("read") == false)
                if let group = group {
                    request = request.filter(Column("group") == group)
                }
                try request.updateAll(db, [Column("read").set(to: true)])
            }
        }catch{
            print("markAllRead error")
        }
        
    }
    
    func delete(allRead: Bool = false, date: Date? = nil) {
        do {
            try dbQueue.write { db in
                var request = Message.all()
                
                // 构建查询条件
                if allRead, let date = date {
                    request = request
                        .filter(Column("read") == true)
                        .filter(Column("createDate") < date)
                } else if allRead {
                    request = request.filter(Column("read") == true)
                } else if let date = date {
                    request = request.filter(Column("createDate") < date)
                } else {
                    return // 没有任何条件，不执行删除
                }
                
                try request.deleteAll(db)
            }
        } catch {
            print("删除消息失败: \(error)")
        }
    }
    func delete(_ message: Message) -> Bool {
        do {
            return try dbQueue.write { db in
                try message.delete(db)
            }
        } catch {
            print("删除消息失败：\(error)")
        }
        return false
    }
    
    func deleteAll(inGroup group: String) -> Bool {
        do {
            return try dbQueue.write { db in
                try Message
                    .filter(Message.Columns.group == group)
                    .deleteAll(db) > 0
            }
        } catch {
            print("删除 group=\(group) 的消息失败：\(error)")
            return false
        }
    }
    
    func deleteExpired() {
        
        do{
            try dbQueue.write { db in
                let now = Date()
                let cutoffDateExpr = now.addingTimeInterval(-1) // 当前时间
                
                // 删除逻辑：
                // ttl != forever（-1） 并且 createDate + ttl天 < now
                try db.execute(sql: """
                        DELETE FROM message
                        WHERE ttl != ?
                          AND datetime(createDate, '+' || ttl || ' days') < ?
                    """, arguments: [ExpirationTime.forever.rawValue, cutoffDateExpr])
            }
        }catch{
            print("删除失败")
        }
        
        
    }
    
    
    static func examples() ->[Message]{
        [
            Message(id: UUID().uuidString, group: String(localized: "示例"), createDate: .now, title: String(localized: "示例"), body: String(localized:  "点击或者滑动可以修改信息状态"), level: 1, ttl: 1, read: false),
            
            Message(id: UUID().uuidString, group: "App", createDate: .now, title: String(localized: "点击跳转app"), body: String(localized:  "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),url: "weixin://", level: 1, ttl: 1, read: false),
            
            Message(id: UUID().uuidString, group: "Markdown", createDate: .now, title: String(localized: "示例"), body: "# Pushback \n## Pushback \n### Pushback",url: "weixin://", level: 1, ttl: 1, read: false)
            
        ]
    }
    
    
}
