//
//  MessageModel.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//
import Foundation
import RealmSwift
import CoreTransferable
import UniformTypeIdentifiers
import SwiftyJSON


final class Message: Object, ObjectKeyIdentifiable, Codable  {
    
	@Persisted(primaryKey: true) var id:UUID
	@Persisted(indexed: true) var group:String
	@Persisted(indexed: true) var createDate:Date
	@Persisted var title:String?
	@Persisted var subtitle:String?
	@Persisted var body:String?
	@Persisted var icon:String?
	@Persisted var url:String?
	@Persisted var image:String?
    @Persisted var from:String?
    @Persisted var host:String?
	@Persisted var level:Int = 1
    @Persisted var ttl:Int = ExpirationTime.forever.days
	@Persisted var read:Bool = false

    

	enum CodingKeys: CodingKey {
		case id
		case title
		case subtitle
		case body
		case icon
		case group
		case url
		case image
		case from
		case level
		case createDate
		case ttl
		case read
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.group, forKey: .group)
        try container.encode(self.createDate.timeIntervalSince1970, forKey: .createDate)
		try container.encode(self.title, forKey: .title)
		try container.encode(self.subtitle, forKey: .subtitle)
		try container.encode(self.body, forKey: .body)
		try container.encode(self.icon, forKey: .icon)
		try container.encode(self.image, forKey: .image)
		try container.encode(self.url, forKey: .url)
		try container.encode(self.from, forKey: .from)
		try container.encode(self.level, forKey: .level)
		try container.encode(self.ttl, forKey: .ttl)
		try container.encode(self.read, forKey: .read)
	}
    
    var search:String{  [ group, title, subtitle, body, from, url].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ";") + ";" }
    
}



extension Message{
    
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
    
    func toCopy() -> MessageCopy {
            MessageCopy(
                id: self.id,
                group: self.group,
                createDate: self.createDate,
                title: self.title,
                subtitle: self.subtitle,
                body: self.body,
                icon: self.icon,
                url: self.url,
                image: self.image,
                from: self.from,
                host: self.host,
                level: self.level,
                ttl: self.ttl,
                read: self.read
            )
        }
}

extension ResultsSection: @retroactive Hashable{
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
}


extension Object {
	func toDictionary() -> [String: AnyObject] {
		
		var dicProps = [String: AnyObject]()
		self.objectSchema.properties.forEach { property in
			
			if property.isArray {
				// 处理 List 类型
				if let listValue = self[property.name] as? List<String> {
					let images:[String] = listValue.compactMap({ $0 })
					dicProps[property.name] = images as AnyObject
				} else {
					var arr: [[String: AnyObject]] = []
					for obj in self.dynamicList(property.name) {
						arr.append(obj.toDictionary())
					}
					dicProps[property.name] = arr as AnyObject
				}
			}else if let value = self[property.name] as? UUID{
				dicProps[property.name] = value.uuidString as AnyObject
			} else if let value = self[property.name] as? Object {
				dicProps[property.name] = value.toDictionary() as AnyObject
			} else if let value = self[property.name] as? Date {
				dicProps[property.name] = Int64(value.timeIntervalSince1970) as AnyObject
			} else if let value = self[property.name] as? Bool {
				dicProps[property.name] = value as NSNumber  // 使用 NSNumber 来包装 Bool
			}else {
				let value = self[property.name]
				dicProps[property.name] = value as AnyObject
			}
		}
		return dicProps
	}
}


extension UTType {
	static var trnExportType = UTType(exportedAs: "me.uuneo.pushback.exv")
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }
}



struct MessageCopy: Codable {
    var id: UUID
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
}
