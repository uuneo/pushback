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
	func savePushServerModel(_ model: PushServerModel, completion: @escaping (Result<CKRecord, Error>) -> Void) {

		if model.key.count < 3 {
			return
		}
		let recordID = CKRecord.ID(recordName: model.id)
		let record = CKRecord(recordType: recordType, recordID: recordID)
		record["url"] = model.url as CKRecordValue
		record["key"] = model.key as CKRecordValue

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
	func fetchPushServerModels(completion: @escaping (Result<[PushServerModel], Error>) -> Void) {
		let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
		
		database.fetch(withQuery: query, inZoneWith: nil) { result in
			DispatchQueue.main.async {
				switch result {
				case .success(let (matchResults, _)): // 解包 matchResults 和 queryCursor
					// 解析 matchResults，获取 CKRecord
					let models: [PushServerModel] = matchResults.compactMap { matchResult in
						switch matchResult.1 {
						case .success(let record):
							return self.recordToPushServerModel(record)
						case .failure(let error):
							print("Error fetching record: \(error.localizedDescription)")
							return nil
						}
					}
					completion(.success(models))

				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
	
	// MARK: - 将 CKRecord 转换为 PushServerModel
	private func recordToPushServerModel(_ record: CKRecord) -> PushServerModel? {
		guard
			let url = record["url"] as? String,
			let key = record["key"] as? String
		else {
			return nil
		}
		return PushServerModel(id: record.recordID.recordName, url: url, key: key)
	}
	
	
	func updatePushServers(items: [PushServerModel]) {
		// 获取云端现有数据
		self.fetchPushServerModels { response in
			switch response {
			case .success(let results):
				// 创建 Set 集合来高效比较
				let cloudItemsSet = Set(results.map { $0.id })
				
				// 找到本地有但云端没有的项
				let itemsToUpload = items.filter { !cloudItemsSet.contains($0.id) }
				
				// 保存这些未在云端的项
				for item in itemsToUpload {
					if item.key != ""{
						self.savePushServerModel(item) { result in
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
					self.savePushServerModel(item) { response in
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
	func deleteCloudServer(_ serverID: String, completion: @escaping (Error?) -> Void) {
		// 创建 CKRecord.ID 对象
		let recordID = CKRecord.ID(recordName: serverID)
		
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
