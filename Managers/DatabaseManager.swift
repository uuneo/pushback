//
//  DatabaseManager.swift
//  pushback
//
//  Created by lynn on 2025/5/26.
//
import GRDB
import Foundation

public class DatabaseManager {
    
    public static let shared = try! DatabaseManager()

    
    public let dbPool: DatabasePool
    public let localPath:URL
    
    private init() throws {
        let local = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pushback")
        guard let local = local else {
            throw NSError(domain: "App", code: 1, userInfo: [NSLocalizedDescriptionKey: "创建容器失败"])
        }
        let path = local.appendingPathComponent("pushback.sqlite", conformingTo: .database)
        self.localPath = path
        // DatabasePool 只在这里创建一次
        self.dbPool = try DatabasePool(path: path.path)
        
        try Message.createInit(dbPool: dbPool)
        try ChatGroup.createInit(dbPool: dbPool)
        try ChatMessage.createInit(dbPool: dbPool)
        try ChatPrompt.createInit(dbPool: dbPool)
        try PttMessageModel.createInit(dbPool: dbPool)
    }
    
    func checkDriveData(complete: @escaping (Bool) -> Void) {
        Task.detached(priority: .userInitiated) {
            do{
               
                let messages = try Self.shared.dbPool.read { db in
                    try Message.fetchAll(db)
                }
                
                let chatgroups = try Self.shared.dbPool.read { db in
                    try ChatGroup.fetchAll(db)
                }
                
                let chatMessages = try Self.shared.dbPool.read { db in
                    try ChatMessage.fetchAll(db)
                }
                
                let chatPrompts = try Self.shared.dbPool.read { db in
                    try ChatPrompt.fetchAll(db)
                }
                
                try self.dbPool.write { db in
                    try db.drop(table: Message.databaseTableName)
                    try db.drop(table: ChatGroup.databaseTableName)
                    try db.drop(table: ChatMessage.databaseTableName)
                    try db.drop(table: ChatPrompt.databaseTableName)
                    
                    db.clearSchemaCache()
                }
                
                try self.dbPool.vacuum()
                
                try Message.createInit(dbPool: self.dbPool)
                try ChatGroup.createInit(dbPool: self.dbPool)
                try ChatMessage.createInit(dbPool: self.dbPool)
                try ChatPrompt.createInit(dbPool: self.dbPool)
                
                try self.dbPool.write { db in
                    for message in messages {
                        try message.insert(db)
                    }
                    for chatgroup in chatgroups {
                        try chatgroup.insert(db)
                    }
                    for chatMessage in chatMessages{
                        try chatMessage.insert(db)
                    }
                    
                    for chatPrompt in chatPrompts{
                        try chatPrompt.insert(db)
                    }
                }
                
                try self.dbPool.vacuum()
                
                complete(true)
                
            }catch{
                Log.error(error.localizedDescription)
                complete(false)
            }
        }
    }

}

extension DatabaseManager{
    static func examples() ->[Message]{
        [
            Message(id: UUID().uuidString, group: "Markdown", createDate: .now,
                    title: String(localized: "示例"),
                    body: "# Pushback \n## Pushback \n### Pushback", level: 1, ttl: 1, read: false),
            
            Message(id: UUID().uuidString, group: String(localized: "示例"), createDate: .now + 10,
                    title: String(localized: "使用方法"),
                    body: String(localized:  """
                        * 左上角切换分组显示
                        * 右上角示例和删除消息
                        * 单击图片/双击消息全屏查看
                        * 左滑删除，右滑朗读，长按显示菜单。
                        """),
                    level: 1, ttl: 1, read: false),
            
            Message(id: UUID().uuidString, group: "App", createDate: .now ,
                    title: String(localized: "点击跳转app"),
                    body: String(localized:  "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),
                    url: "weixin://", level: 1, ttl: 1, read: false)
        ]
    }
    
    func unreadCount(group: String? = nil) -> Int {
        do{
            return try  dbPool.read { db in
                var request = Message.filter(Column("read") == false)
                
                if let group = group {
                    request = request.filter(Column("group") == group)
                }
    
                return try request.fetchCount(db)
            }
        }catch{
            Log.error("查询失败")
            return 0
        }
        
    }
    
    func count(group: String? = nil) -> Int {
        do{
            let count = try  dbPool.read { db in
                if let group = group{
                    return  try Message.filter(Message.Columns.group == group).fetchCount(db)
                }else {
                    return  try Message.fetchCount(db)
                }
               
            }
            return count
        }catch{
            Log.error(error.localizedDescription)
            return 0
        }
    }
    
    func add(_ message: Message) async  {
        do {
            try await  dbPool.write { db in
                try message.insert(db, onConflict: .replace)
            }
        } catch {
            Log.error("Add or update message failed:", error)
        }
    }
    
    func query(id: String) -> Message? {
        do {
            return try  dbPool.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            Log.error("Failed to query message by id:", error)
            return nil
        }
    }
    func query(id: String) async -> Message? {
        do {
            return try await  dbPool.read { db in
                try Message.fetchOne(db, key: id)
            }
        } catch {
            Log.error("Failed to query message by id:", error)
            return nil
        }
    }
    func query(search: String, group: String? = nil,
               limit lim: Int = 50, _ date: Date? = nil) async -> ([Message], Int) {
        
        // 1. 分词，去掉空字符串
        let keywords = search
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            return try await dbPool.read { db in
                var request = Message.all()

                // 2. 多关键词叠加 AND 条件
                for keyword in keywords {
                    let escaped = keyword
                        .replacingOccurrences(of: "%", with: "\\%")
                        .replacingOccurrences(of: "_", with: "\\_")

                    let pattern = "%\(escaped)%"

                    // 每个关键词作用在所有字段：用 OR
                    let perKeywordFilter =
                        Message.Columns.title.like(pattern)
                        || Message.Columns.subtitle.like(pattern)
                        || Message.Columns.body.like(pattern)
                        || Message.Columns.group.like(pattern)
                        || Message.Columns.url.like(pattern)

                    // 每个关键词之间用 AND 累加
                    request = request.filter(perKeywordFilter)
                }

                // 3. 附加其他过滤条件
                if let group = group {
                    request = request.filter(Message.Columns.group == group)
                }

                if let date = date {
                    request = request.filter(Message.Columns.createDate < date)
                }

                // 4. 排序与限制
                request = request
                    .order(Message.Columns.createDate.desc)
                    .limit(lim)

                return (try request.fetchAll(db), try request.fetchCount(db))
            }
        } catch {
            Log.error("Query error: \(error)")
            return ([], 0)
        }
    }
    
    func queryGroup() async -> [Message]{
        do {
            return try await dbPool.read { db in
                try self.fetchGroupedMessages(from: db)
            }
        } catch {
            Log.error("Failed to query messages:", error)
            return []
        }
    }
    
    func queryGroup() -> [Message] {
        do {
            return try dbPool.read { db in
                try self.fetchGroupedMessages(from: db)
            }
        } catch {
            Log.error("Failed to query messages:", error)
            return []
        }
    }
    
    
    private func fetchGroupedMessages(from db: Database) throws -> [Message] {
        let rows = try Row.fetchAll(db, sql: """
            SELECT m.*, unread.count AS unreadCount
            FROM (
                SELECT *
                FROM (
                    SELECT *,
                           ROW_NUMBER() OVER (PARTITION BY "group" ORDER BY createDate DESC, id DESC) AS rn
                    FROM message
                )
                WHERE rn = 1
            ) AS m
            LEFT JOIN (
                SELECT "group", COUNT(*) AS count
                FROM message
                WHERE read = 0
                GROUP BY "group"
            ) AS unread
            ON m."group" = unread."group"
            ORDER BY unread.count DESC NULLS LAST, m.createDate DESC
        """)

        return try rows.map { try Message(row: $0) }
    }
    
    func query(group: String? = nil, limit lim: Int = 50, _ date: Date? = nil) async -> [Message] {
        do {
            return try await  dbPool.read { db in
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
            Log.error("Query failed:", error)
            return []
        }
    }
    
    func markAllRead(group: String? = nil) async {
        do{
            try await self.dbPool.write { db in
                var request = Message.filter(Column("read") == false)
                if let group = group {
                    request = request.filter(Column("group") == group)
                }
                try request.updateAll(db, [Column("read").set(to: true)])
            }
        }catch{
            Log.error("markAllRead error")
        }
    }
    
    func delete(allRead: Bool = false, date: Date? = nil) async {
        do {
            try await self.dbPool.write { db in
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
            Log.error("删除消息失败: \(error)")
        }
    }
    func delete(_ message: Message, in group: Bool = false) async -> Int {
        do {
            if group{
                return try await dbPool.write { db in
                    try Message
                        .filter(Message.Columns.group == message.group)
                        .deleteAll(db)
                    
                    return try Message.filter(Message.Columns.group == message.group).fetchCount(db)
                }
            }
            return try await dbPool.write { db in
                try message.delete(db)
                return try Message.filter(Message.Columns.group == message.group).fetchCount(db)
            }
        } catch {
            Log.error("删除消息失败：\(error)")
        }
        return -1
    }
    
    func delete(_ messageId: String) -> String?{
        do{
            return  try dbPool.write { db in
                if  let message = try Message.filter(Message.Columns.id == messageId).fetchOne(db){
                    try message.delete(db)
                    return message.group
                }
                return nil
            }
        }catch{
            Log.error("删除消息失败：\(error)")
            return nil
        }
        
    }
    
    
    func deleteExpired() async {
        
        do{
            try await dbPool.write { db in
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
            Log.error("删除失败")
        }
        
        
    }
    
    
   
    
    
    static func CreateStresstest(max number:Int = 10000)  async -> Bool {

        return ((try? await  Self.shared.dbPool.write { db in
            for k in 0...number{
                let message =  Message(id: UUID().uuidString,
                                       group: "\(k % 10)",
                                       createDate: .now,
                                       title: "\(k) Test",
                                       body: "Text Data \(k)",
                                       level: 1,
                                       ttl: 1,
                                       read: false)
                try message.insert(db)
            }
            return true
        }) != nil)
    }

    static func ensureMarkdownLineBreaks(_ text: String) -> String {
        // 将文本按行分割
        let lines = text.components(separatedBy: .newlines)
        
        // 处理每一行：检查结尾是否已经有两个空格
        let processedLines = lines.map { line in
            if line.hasSuffix("  ") || line.isEmpty {
                return line
            } else {
                return line + "  "  // 添加两个空格
            }
        }
        
        // 使用 \n 连接回去
        return processedLines.joined(separator: "\n")
    }
    
}
