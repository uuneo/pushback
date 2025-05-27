//
//  ChatMessageModel.swift
//  pushback
//
//  Created by uuneo on 2025/2/25.
//


import Foundation
import GRDB

struct ChatGroup: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
     var id: String = UUID().uuidString
     var timestamp: Date
     var name: String = String(localized: "新对话")
     var host: String
     var current:Bool = false
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let name = Column(CodingKeys.name)
        static let host = Column(CodingKeys.host)
        static let current = Column(CodingKeys.current)
    }
    
    static func createInit(dbQueue: DatabasePool) throws {
        try dbQueue.write { db in
            try db.create(table: "chatGroup", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .date).notNull()
                t.column("name", .text).notNull()
                t.column("host", .text).notNull()
                t.column("current", .boolean)
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
    
    static func createInit(dbQueue: DatabasePool) throws {
        try dbQueue.write { db in
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
    var selected: Bool
    
    
    enum Columns{
        static let id = Column(CodingKeys.id)
        static let timestamp = Column(CodingKeys.timestamp)
        static let title = Column(CodingKeys.title)
        static let content = Column(CodingKeys.content)
        static let inside = Column(CodingKeys.inside)
        static let selected = Column(CodingKeys.selected)
    }
    
    static func createInit(dbQueue: DatabasePool) throws {
        try dbQueue.write { db in
            try db.create(table: "chatMessage", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("timestamp", .text).notNull()
                t.column("title", .text).notNull()
                t.column("content", .date).notNull()
                t.column("inside", .boolean)
                t.column("selected", .boolean)
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
             """), inside: true, selected: false),
        ChatPrompt( timestamp: .now,title: String(localized: "翻译助手"), content: String(localized: """
             作为一名专业翻译，你精通多国语言，擅长准确传达原文的含义和风格。你的职责包括：
             1. 保持原文的语气和风格。
             2. 考虑文化差异和语言习惯。
             3. 在必要时提供注释或说明。
             4. 对专业术语进行解释和澄清。
             """), inside: true, selected: false),
        ChatPrompt( timestamp: .now,title: String(localized: "写作助手"), content: String(localized: """
             作为一名专业写作助手，你擅长各类文体的写作和润色。你的任务包括：
             1. 改进文章结构和逻辑。
             2. 优化用词和表达方式。
             3. 确保文章连贯性和流畅性。
             4. 突出重点内容和核心信息。
             5. 使文章符合目标读者的阅读习惯。
             """), inside: true, selected: false)
    ]
}
