//
//  MessageModel.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//
import GRDB
import Foundation

struct Message: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String
    var group: String
    var createDate: Date
    var title: String?
    var subtitle: String?
    var body: String?
    var icon: String?
    var url: String?
    var image: String?
    var from: String?
    var host: String?
    var level: Int
    var ttl: Int
    var read: Bool
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let group = Column(CodingKeys.group)
        static let createDate = Column(CodingKeys.createDate)
        static let title = Column(CodingKeys.title)
        static let subtitle = Column(CodingKeys.subtitle)
        static let body = Column(CodingKeys.body)
        static let icon = Column(CodingKeys.icon)
        static let url = Column(CodingKeys.url)
        static let image = Column(CodingKeys.image)
        static let from = Column(CodingKeys.from)
        static let host = Column(CodingKeys.host)
        static let level = Column(CodingKeys.level)
        static let ttl = Column(CodingKeys.ttl)
        static let read = Column(CodingKeys.read)
    }
    
}

extension Message{
    static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "message", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("group", .text).notNull()
                t.column("createDate", .date).notNull()
                t.column("title", .text)
                t.column("subtitle", .text)
                t.column("body", .text)
                t.column("icon", .text)
                t.column("url", .text)
                t.column("image", .text)
                t.column("from", .text)
                t.column("host", .text)
                t.column("level", .integer).notNull()
                t.column("ttl", .integer).notNull()
                t.column("read", .boolean).notNull()
            }
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS idx_message_group_createdate
                ON message("group", createDate DESC)
            """)
        }
        

    }
    
    var search:String{  [ group, title, subtitle, body, from, url].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ";") + ";" }
    
    
    func isExpired() -> Bool{
        /// 兼容老版本的使用
        if self.ttl == ExpirationTime.forever.rawValue{ return false}
        return self.createDate.isExpired(days: self.ttl)
    }

    func expiredTime() -> String {

        if self.ttl == ExpirationTime.forever.rawValue{
            return "∞ ∞ ∞"
        }

        let days = self.createDate.daysRemaining(afterSubtractingFrom: self.ttl)
        if days <= 0 {
            return String(localized: "已过期")
        }

        let calendar = Calendar.current
        let now = Date()
        let targetDate = calendar.date(byAdding: .day, value: days, to: now)!

        let components = calendar.dateComponents([.year, .month, .day], from: now, to: targetDate)

        if let years = components.year, years > 0 {
            return String(localized: "\(years)年")
        } else if let months = components.month, months > 0 {
            return String(localized: "\(months)个月")
        } else if let days = components.day {
            return String(localized: "\(days)天")
        }

        return String(localized:"即将过期")
    }
    
    var voiceText: String{
        var text:[String] = []
        
        if let title{
            text.append(title)
        }
        
        if let subtitle{
            text.append(subtitle)
        }
        
        if let body{
            text.append(PBMarkdown.plain(body))
        }
        
        return text.joined(separator: ",")
    }
    
    
}


struct ChatGroup: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
     var id: String = UUID().uuidString
     var timestamp: Date
     var name: String = String(localized: "新对话")
     var host: String
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
    }
    
    static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatGroup", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .date).notNull()
                t.column("name", .text).notNull()
                t.column("host", .text).notNull()
            }
        }
        

    }
    
    
}


struct ChatMessage: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var chat:String
    var request:String
    var content: String
    var message:String?
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let chat = Column(CodingKeys.chat)
        static let request = Column(CodingKeys.request)
        static let content = Column(CodingKeys.content)
        static let message = Column(CodingKeys.message)
    }
    
    static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatMessage", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .date).notNull()
                t.column("chat", .text).notNull()
                t.column("request", .text).notNull()
                t.column("content", .text).notNull()
                t.column("message", .text)
            }
        }
    }
}

extension ChatMessage{
    static func getAssistant(chat:ChatMessage?)-> Message{
        var message = Message(id: UUID().uuidString, group: String(localized: "智能助手"), createDate: .now,body: String(localized:"嗨! 我是智能助手,我可以帮你搜索，答疑，写作，请把你的任务交给我吧！"), level: 1, ttl: 1, read: true)
        
        if let chat = chat{
            message.createDate = chat.timestamp
        }
        return message
    }
}


struct ChatPrompt: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var timestamp: Date = .now
    var title: String
    var content: String
    var inside: Bool
    
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let inside = Column(CodingKeys.inside)
    }
    
    static func createInit(dbPool: DatabasePool) throws {
        try dbPool.write { db in
            try db.create(table: "chatPrompt", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .text).notNull()
                t.column("title", .text).notNull()
                t.column("content", .date).notNull()
                t.column("inside", .boolean)
            }
        }
    }
    
    
    static let prompts = [
        
        ChatPrompt( timestamp: .now,title: String(localized: "代码助手"), content: String(localized: """
             作为一名经验丰富的程序员，你擅长编写清晰、简洁且易于维护的代码。在回答问题时：
             1. 提供详细的代码示例。
             2. 解释代码的关键部分。
             3. 指出潜在的优化空间。
             4. 考虑代码的性能和安全性。
             """), inside: true),
        ChatPrompt( timestamp: .now,title: String(localized: "翻译助手"), content: String(localized: """
             作为一名专业翻译，你精通多国语言，擅长准确传达原文的含义和风格。你的职责包括：
             1. 保持原文的语气和风格。
             2. 考虑文化差异和语言习惯。
             3. 在必要时提供注释或说明。
             4. 对专业术语进行解释和澄清。
             """), inside: true),
        ChatPrompt( timestamp: .now,title: String(localized: "写作助手"), content: String(localized: """
             作为一名专业写作助手，你擅长各类文体的写作和润色。你的任务包括：
             1. 改进文章结构和逻辑。
             2. 优化用词和表达方式。
             3. 确保文章连贯性和流畅性。
             4. 突出重点内容和核心信息。
             5. 使文章符合目标读者的阅读习惯。
             """), inside: true)
    ]
}
