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
    static func createInit(dbQueue: DatabasePool) throws {
        try dbQueue.write { db in
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
