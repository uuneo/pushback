//
//  PushServerCloudKit.swift
//  pushback
//
//  Created by He Cho on 2024/10/29.
//
import Foundation
import CloudKit

class PushServerCloudKit {
	static let shared = PushServerCloudKit()
	
	private init() { }
	
	private let database = CKContainer(identifier: BaseConfig.icloudName).privateCloudDatabase
	private let recordType = "PushServerModal"

	// MARK: - 保存记录到私有数据库
	func savePushServerModal(_ modal: PushServerModal, completion: @escaping (Result<CKRecord, Error>) -> Void) {
		
		if modal.key.count < 3 {
			return
		}
		let recordID = CKRecord.ID(recordName: modal.id)
		let record = CKRecord(recordType: recordType, recordID: recordID)
		record["url"] = modal.url as CKRecordValue
		record["key"] = modal.key as CKRecordValue
		
	

		database.save(record) { savedRecord, error in
			DispatchQueue.main.async {
				if let error = error {
					completion(.failure(error))
				} else if let savedRecord = savedRecord {
					completion(.success(savedRecord))
				}
			}
		}
	}

	// MARK: - 从私有数据库获取记录
	func fetchPushServerModals(completion: @escaping (Result<[PushServerModal], Error>) -> Void) {
		let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
		
		database.fetch(withQuery: query, inZoneWith: nil) { result in
			DispatchQueue.main.async {
				switch result {
				case .success(let (matchResults, _)): // 解包 matchResults 和 queryCursor
					// 解析 matchResults，获取 CKRecord
					let modals: [PushServerModal] = matchResults.compactMap { matchResult in
						switch matchResult.1 {
						case .success(let record):
							return self.recordToPushServerModal(record)
						case .failure(let error):
							print("Error fetching record: \(error.localizedDescription)")
							return nil
						}
					}
					completion(.success(modals))
					
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
	
	// MARK: - 将 CKRecord 转换为 PushServerModal
	private func recordToPushServerModal(_ record: CKRecord) -> PushServerModal? {
		guard
			let url = record["url"] as? String,
			let key = record["key"] as? String
		else {
			return nil
		}
		return PushServerModal(id: record.recordID.recordName, url: url, key: key)
	}
	
	
	func updatePushServers(items: [PushServerModal]) {
		// 获取云端现有数据
		self.fetchPushServerModals { response in
			switch response {
			case .success(let results):
				// 创建 Set 集合来高效比较
				let cloudItemsSet = Set(results.map { $0.id })
				
				// 找到本地有但云端没有的项
				let itemsToUpload = items.filter { !cloudItemsSet.contains($0.id) }
				
				// 保存这些未在云端的项
				for item in itemsToUpload {
					if item.key != ""{
						self.savePushServerModal(item) { result in
							switch result {
							case .success:
								print("保存成功: \(item)")
							case .failure(let error):
								print("保存失败: \(error.localizedDescription)")
							}
						}
					}
				}
				
			case .failure(let error):
				debugPrint("获取云端数据失败: \(error.localizedDescription)")
				for item in items {
					self.savePushServerModal(item) { response in
						switch response {
						case .success:
							print("保存成功: \(item)")
						case .failure(let error):
							print("保存失败: \(error.localizedDescription)")
						}
					}
				}
			}
		}
	}
	
	
	// 删除指定的 RingtoneCloudData
	func deleteCloudServer(_ ringtoneID: String, completion: @escaping (Error?) -> Void) {
		// 创建 CKRecord.ID 对象
		let recordID = CKRecord.ID(recordName: ringtoneID)
		
		// 调用数据库的 delete 方法删除记录
		database.delete(withRecordID: recordID) { (deletedRecordID, error) in
			if let error = error {
				// 删除失败时，调用 completion 回调并传递错误信息
				completion(error)
			} else {
				// 删除成功时，调用 completion 回调
				completion(nil)
			}
		}
	}
	
	
	
	
}
