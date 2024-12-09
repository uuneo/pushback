//
//  RingsTongCloudKit.swift
//  pushback
//
//  Created by He Cho on 2024/11/11.
//

import Foundation
import CloudKit
import AVFoundation
import CryptoKit

struct RingtoneCloudData: Codable, Identifiable {
	var id: String
	var name: String
	var prompt: [String] = []
	var count: Int
	var data: URL
	
	init?(name: String, prompt: [String] = [], count: Int = 0, data: URL) {
		if let id = RingtoneCloudData.sha256(for: data){
			self.id = id
		}else {
			return nil
		}
		self.name = name
		self.prompt = prompt
		self.count = count
		self.data = data
	}
	
	func to(_ recordType: String) -> CKRecord {
		let recordID = CKRecord.ID(recordName: self.id)
		let record = CKRecord(recordType: recordType, recordID: recordID)
		record["name"] = self.name as CKRecordValue
		record["prompt"] = self.prompt as CKRecordValue
		record["count"] = self.count as CKRecordValue
		record["data"] = CKAsset(fileURL: self.data)
		return record
	}
	
	init?(data: CKRecord) {
		self.id = data.recordID.recordName
		self.count = data["count"] as? Int ?? 0
		self.prompt = data["prompt"] as? [String] ?? []
		
		if let name = data["name"] as? String {
			debugPrint(name)
			self.name = name
		} else {
			return nil
		}
		if let asset = data["data"] as? CKAsset, let fileURL = asset.fileURL {
			self.data = fileURL
		} else {
			return nil
		}
	}
	
	static func sha256(for fileURL: URL) -> String? {
		do {
			let fileData = try Data(contentsOf: fileURL)
			let hash = SHA256.hash(data: fileData)
			return hash.map { String(format: "%02x", $0) }.joined()
		} catch {
			print("Error reading file data: \(error)")
			return nil
		}
	}
}

class RingsTongCloudKit:ObservableObject {
	static let shared = RingsTongCloudKit()
	private init(){}
	let database = CKContainer(identifier: BaseConfig.icloudName).publicCloudDatabase
	let recordType = BaseConfig.RingTongRecord
	
	// 保存到数据库的方法，确保 name 和 signature 唯一
	func saveRingtone(_ ringtone: RingtoneCloudData, completion: @escaping (Error?) -> Void) {
		let predicate = NSPredicate(format: "name == %@", ringtone.name)
		let query = CKQuery(recordType: recordType, predicate: predicate)
		
		database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
			switch result {
			case .success(let (matchedRecords, _)):
				if !matchedRecords.isEmpty {
					completion(NSError(domain: "RingsTongCloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Record with the same name or signature already exists."]))
					return
				}
				
				let newRecord = ringtone.to(self?.recordType ?? BaseConfig.RingTongRecord)
				self?.database.save(newRecord) { _, saveError in
					completion(saveError)
				}
				
			case .failure(let error):
				completion(error)
			}
		}
	}
	
	// 查询 count 排序后的前 30 条数据
	func fetchTop30ByCount(completion: @escaping ([RingtoneCloudData]?, Error?) -> Void) {
		let predicate = NSPredicate(value: true)
		let query = CKQuery(recordType: recordType, predicate: predicate)
		query.sortDescriptors = [NSSortDescriptor(key: "count", ascending: false)]
		
		let operation = CKQueryOperation(query: query)
		operation.resultsLimit = 30
		
		var fetchedRecords: [RingtoneCloudData] = []
		
		// 使用 recordMatchedBlock 处理每条记录
		operation.recordMatchedBlock = { recordID, recordResult in
			switch recordResult {
			case .success(let record):
				if let ringtone = RingtoneCloudData(data: record) {
					fetchedRecords.append(ringtone)
				}
			case .failure(let error):
				print("Error fetching record \(recordID): \(error.localizedDescription)")
			}
		}
		
		// 使用 queryResultBlock 处理查询结果
		operation.queryResultBlock = { result in
			switch result {
			case .success:
				completion(fetchedRecords, nil)
			case .failure(let error):
				completion(nil, error)
			}
		}
		
		database.add(operation)
	}
	
	// 根据搜索词查询 prompt 中包含搜索词的记录，并按时间排序
	func fetchByPromptContaining(_ searchTerm: String, cursor: CKQueryOperation.Cursor? = nil, completion: @escaping ([RingtoneCloudData]?, CKQueryOperation.Cursor?, Error?) -> Void) {
		let predicate = NSPredicate(format: "ANY prompt CONTAINS[c] %@", searchTerm)
		let query = CKQuery(recordType: recordType, predicate: predicate)
		query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
		
		let operation = cursor == nil ? CKQueryOperation(query: query) : CKQueryOperation(cursor: cursor!)
		
		var fetchedRecords: [RingtoneCloudData] = []
		
		// 使用 recordMatchedBlock 处理每条记录
		operation.recordMatchedBlock = { recordID, recordResult in
			switch recordResult {
			case .success(let record):
				if let ringtone = RingtoneCloudData(data: record) {
					fetchedRecords.append(ringtone)
				}
			case .failure(let error):
				print("Error fetching record \(recordID): \(error.localizedDescription)")
			}
		}
		
		// 使用 queryResultBlock 处理查询结果
		operation.queryResultBlock = { result in
			switch result {
			case .success(let nextCursor):
				completion(fetchedRecords, nextCursor, nil)
			case .failure(let error):
				completion(nil, nil, error)
			}
		}
		
		database.add(operation)
	}
	
	
	
}
