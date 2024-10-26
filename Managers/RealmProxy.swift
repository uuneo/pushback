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
	
	
	static func exportFiles(_ items:Results<Message>, completion: @escaping ((URL?,String?)-> Void)){
		
		Task.detached(priority: .high){
			do{
				
				var arr = [[String: AnyObject]]()
				for message in items {
					arr.append(message.toDictionary())
				}
				
				
				let jsonData = try JSON(arr).rawData(options: JSONSerialization.WritingOptions.prettyPrinted)
				
				let fileManager = FileManager.default
				let tempDirectoryURL = fileManager.temporaryDirectory
				let fileName = "meow_\(Date().formatString(format: "yyyy_MM_dd_HH_mm_ss")).json"
				let linkURL = tempDirectoryURL.appendingPathComponent(fileName)
				
				// 清空temp文件夹
				try fileManager
					.contentsOfDirectory(at: tempDirectoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
					.forEach { file in
						try? fileManager.removeItem(atPath: file.path)
					}
				// 写入临时文件
				try jsonData.write(to: linkURL)
				
				
				await MainActor.run {
					completion(linkURL,String(localized: "导出成功"))
				}
			} catch {
#if DEBUG
				print("errors: \(error.localizedDescription)")
#endif
				await MainActor.run {
					completion(nil, error.localizedDescription)
				}
			}
			
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
						messageObject.id = id
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
