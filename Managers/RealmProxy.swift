//
//  RealmProxy.swift
//  pushback
//
//  Created by He Cho on 2024/10/9.
//
import SwiftUI
import RealmSwift
import Defaults
import SwiftyJSON

class RealmProxy{
	
	static let shared = RealmProxy()
	private init(){}
	
	
	
	private func realm(completion: @escaping (Realm) -> Void, fail: ((String)->Void)? = nil){
		do{
			let proxy = try Realm()
			
			try proxy.write {
				completion(proxy)
			}
			
		}catch{
			fail?(error.localizedDescription)
		}
	}
	
	func delete(_ date: Date){
		
		self.realm { proxy in
			let messages = proxy.objects(Message.self).where({ $0.createDate < date })
			for msg in messages{
				proxy.delete(msg)
			}
		}
		
	}
	
	func read(_ read: Bool){
		self.realm { proxy in
			let messages = proxy.objects(Message.self).filter({
				(msg) -> Bool in
				msg.read == read
			})
			
			for msg in messages{
				proxy.delete(msg)
			}
			
			RealmProxy.ChangeBadge()
		}
		
	}
	
	func read(_ group: String? = nil){
		
		self.realm { proxy in
			let messages = proxy.objects(Message.self).filter({
				(msg) -> Bool in
				if let group = group{
					msg.group == group
				}else{
					true
				}
			})
			
			for msg in messages{
				msg.read = true
			}
			
			RealmProxy.ChangeBadge()
		}
		
		
	}
	
	func deleteExpired() {
		self.realm { proxy in
			let messages =  proxy.objects(Message.self).filter({$0.isExpired()})
			for msg in messages{
				proxy.delete(msg)
			}
			RealmProxy.ChangeBadge()
		}
	}
	
	func delete(_ group: String){
		
		self.realm { proxy in
			let messages = proxy.objects(Message.self).filter( {$0.group == group} )
			
			for msg in messages{
				proxy.delete(msg)
			}
			RealmProxy.ChangeBadge()
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
				RealmProxy.ChangeBadge()
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

	func importMessage(_ data: [URL]) -> String {
		do{
			
			guard let url = data.first else { return String(localized: "文件不存在")}
			
			if url.startAccessingSecurityScopedResource(){
				let data = try Data(contentsOf: url)
				let json = try JSON(data: data)
				
				guard let arr = json.array else {
					return String(localized: "文件格式错误")
				}
				
				self.realm { proxy in
					for message in arr {
						guard let id = message["id"].string else {
							continue
						}
						guard let createDate = message["createDate"].int64 else {
							continue
						}

						let title = message["title"].string
						let body = message["body"].string
						let url = message["url"].string
						let read = message["read"].boolValue
						let group = message["group"].string
				

						let messageObject = Message()
						
						if let idString = UUID(uuidString: id){
							messageObject.id = idString
						}
						messageObject.title = title
						messageObject.body = body
						messageObject.url = url
						messageObject.group = group ?? String(localized: "导入数据")
						messageObject.read = read
						messageObject.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
						proxy.add(messageObject, update: .modified)
					}
				}
				
			}
			
			
			return String(localized: "导入成功")
			
		}catch{
			debugPrint(error)
			return error.localizedDescription
		}
	}
	
	
}
