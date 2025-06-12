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


struct ChatGroup: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Equatable {
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
    
    static let prompts = ChatPromptMode.prompts

}



enum ChatPromptMode: Equatable{
    case summary(String?)
    case translate(String?)
    case writing(String?)
    case code(String?)
    case abstract(String?)
    
    
    var prompt: ChatPrompt{
        switch self {
        case .summary(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "总结助手"),
                content: String(localized: """
                你是一名专业总结助手，擅长从大量信息中提炼关键内容。总结时请遵循以下原则：
                1. 提取核心观点，排除冗余信息。
                2. 保持逻辑清晰，结构紧凑, 确定文章的中心主题，理解作者的论点和观点。
                3. 列出关键点来传达文章的信息和细节。确保总结保持一致性，语言简洁明了
                4. 可根据需要生成段落式或要点式总结, 遵循原文结构以提升阅读体验。
                5. 有效地传达主要观点和情感层面，同时使用简洁清晰的语言
                下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                """),
                inside: true
            )
        case .translate(let lang):
            ChatPrompt(
               timestamp: .now,
               title: String(localized: "翻译助手"),
               content: String(localized: """
               你是一名专业翻译，精通多国语言，能够准确传达原文含义与风格。翻译时请遵循以下要点：
               1. 保持语气一致，忠实还原原文风格。
               2. 合理调整以符合目标语言习惯与文化。
               3. 优先选择自然、通顺的表达方式, 只返回翻译，不要添加任何其他内容。
               下面我给你内容，直接按照 \(lang ?? Self.lang()) 进行翻译.
               """),
               inside: true
           )
        case .writing(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "写作助手"),
                content: String(localized: """
                你是一名专业写作助手，擅长各类文体的写作与润色。请根据以下要求优化文本：
                1. 明确文章结构，增强逻辑连贯性。
                2. 优化用词，使语言更准确流畅。
                3. 强调重点，突出核心信息。
                4. 使风格贴合目标读者的阅读习惯。
                5. 纠正语法、标点和格式错误。
                下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                """),
                inside: true
            )
        case .code(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "代码助手"),
                content: String(localized: """
                你是一位经验丰富的程序员，擅长编写清晰、简洁、易于维护的代码。请根据以下原则回答问题：
                1. 提供完整、可运行的代码示例。
                2. 简明解释关键实现细节。
                3. 指出潜在的性能或结构优化点。
                4. 关注代码的可扩展性、安全性和效率。
                下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                """),
                inside: true
            )
        case .abstract(let lang):
            ChatPrompt(
                timestamp: .now,
                title: String(localized: "摘要助手"),
                content: String(localized: """
                    你是一名专业摘要助手，擅长用简洁准确的语言提炼关键信息。
                    请基于以下内容，提炼出 2~3 句话，清晰概括核心观点和情感基调。
                    仅输出摘要内容，不添加解释或说明。
                    下面我给你内容，直接按照 \(lang ?? Self.lang()) 语言给我回复
                    """),
                inside: true
            )
        }
    }

    
    static var prompts:[ChatPrompt]{
        [Self.summary(lang()).prompt, Self.translate(lang()).prompt, Self.writing(lang()).prompt, Self.code(lang()).prompt]
    }
    
    
    static func lang() -> String{
        let currentLang = Defaults[.lang]
        if let code = Locale(identifier: currentLang).language.languageCode?.identifier,
           let lang =  Locale.current.localizedString(forLanguageCode: code){
           
           return lang
        }
        return "English"
    }
}
