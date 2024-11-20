//
//  MessageModal.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//
import Foundation
import RealmSwift
import CoreTransferable
import UniformTypeIdentifiers
import SwiftyJSON


final class Message: Object , ObjectKeyIdentifiable, Codable {
	@Persisted var id:String = UUID().uuidString
	@Persisted var title:String?
	@Persisted var body:String?
	@Persisted var icon:String?
	@Persisted var group:String = "Basic"
	@Persisted var url:String?
	@Persisted var from:String?
	@Persisted var mode:String = "999"
	@Persisted var createDate = Date()
	@Persisted var saveDays:Int = -1
	@Persisted var read:Bool = false
	
	override class func primaryKey() -> String? {
		return "id"
	}

	override class func indexedProperties() -> [String] {
		return ["group", "createDate", "from"]
	}
	
	
	enum CodingKeys: CodingKey {
		case id
		case title
		case body
		case icon
		case group
		case url
		case from
		case mode
		case createDate
		case saveDays
		case read
	}
	
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.title, forKey: .title)
		try container.encode(self.body, forKey: .body)
		try container.encode(self.icon, forKey: .icon)
		try container.encode(self.group, forKey: .group)
		try container.encode(self.url, forKey: .url)
		try container.encode(self.from, forKey: .from)
		try container.encode(self.mode, forKey: .mode)
		try container.encode(self.createDate, forKey: .createDate)
		try container.encode(self.saveDays, forKey: .saveDays)
		try container.encode(self.read, forKey: .read)
	}
	
	
}

extension Message{
   
		static let messages = [
			
		   
			Message(value: ["title":  String(localized: "示例"),"group":  String(localized: "示例"),"body": String(localized:  "点击或者滑动可以修改信息状态"),"icon":"warn","mode":"999"]),
			
			Message(value: ["group":  "App","title":String(localized: "点击跳转其他app") ,"body":String(localized:  "url属性可以打开URLScheme, 点击通知消息自动跳转，前台收到消息自动跳转"),"url":"weixin://","icon":"weixin","mode":"999"])
		]
	
	
	
}


extension Message{
	
	func update(completion: @escaping (Message?) -> Void){
		do {
			let realm = try Realm()
			try realm.write {
				completion(realm.objects(Message.self).first(where: {$0 == self}))
			}
			
		}catch{
			completion(nil)
		}
	}
	
	func isRead(completion: ((String)-> Void)? = nil) {
		do {
			let realm = try Realm()
			try realm.write {
				if let data = realm.objects(Message.self).first(where: {$0 == self}){
					data.read = !data.read
					completion?(String(localized: "修改成功"))
				}else{
					completion?(String(localized: "没有数据"))
				}
				
			}
			
		}catch{
			completion?(error.localizedDescription)
		}
	}
	
	func delete(completion: ((String)-> Void)? = nil){
		do {
			let realm = try Realm()
			try realm.write {
				if let data = realm.objects(Message.self).first(where: {$0 == self}){
					data.read = !data.read
					completion?(String(localized: " 删除成功"))
				}else{
					completion?(String(localized: "没有数据"))
				}
			}
			
		}catch{
			completion?(error.localizedDescription)
		}
	}
	
	func isExpired() -> Bool{
		self.createDate.isExpired(days: self.saveDays)
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
				var arr: [[String: AnyObject]] = []
				for obj in self.dynamicList(property.name) {
					arr.append(obj.toDictionary())
				}
				dicProps[property.name] = arr as AnyObject
			} else if let value = self[property.name] as? Object {
				dicProps[property.name] = value.toDictionary() as AnyObject
			} else if let value = self[property.name] as? Date {
				dicProps[property.name] = Int64(value.timeIntervalSince1970) as AnyObject
			} else if let value = self[property.name] as? Bool {
				dicProps[property.name] = value as NSNumber  // 使用 NSNumber 来包装 Bool
			} else {
				let value = self[property.name]
				dicProps[property.name] = value as AnyObject
			}
		}
		return dicProps
	}
}



struct MessageExportJson:Transferable, Identifiable {
	static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(exportedContentType: .trnExportType, exporting: \.data)
			.suggestedFileName("pushback_\(Date().formatString(format:"yyyy_MM_dd_HH_mm_ss"))")
			
	}
	
	public var id:UUID = UUID()
	public var data: Data
	
	init(data: [Message]) {
		
		let results = data.compactMap({ $0.toDictionary() })
		
		let data = try! JSON(results).rawData(options: JSONSerialization.WritingOptions.prettyPrinted)
		self.data = data
	}
}


extension UTType {
	static var trnExportType = UTType(exportedAs: "me.uuneo.pushback.exv")
}
