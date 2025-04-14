//
//  PushServerCloudKit.swift
//  pushback
//
//  Created by uuneo 2024/10/29.
//
import Foundation
import CloudKit
import Defaults

class PushServerCloudKit {
	static let shared = PushServerCloudKit()
	
	private init() { }
    
    private let container = CKContainer(identifier: BaseConfig.icloudName)
    
    private var database: CKDatabase {  container.privateCloudDatabase }
    private var publicDB: CKDatabase {  container.publicCloudDatabase }
	
	private let recordType = "PushServerModal"

	// MARK: - 保存记录到私有数据库
	func savePushServerModel(_ model: PushServerModel, completion: @escaping (Result<CKRecord, Error>) -> Void) {

		if model.key.count < 3 { return }
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
                    self.removeDuplicates()
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
                            Log.error("Error fetching record: \(error.localizedDescription)")
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
                                Log.debug("保存成功: \(item)")
							case .failure(let error):
                                Log.error("保存失败: \(error.localizedDescription)")
							}
						}
					}
				}
				
			case .failure(let error):

				Log.debug("获取云端数据失败: \(error.localizedDescription)")
				for item in items {
					self.savePushServerModel(item) { response in
						switch response {
						case .success:
                            Log.debug("保存成功: \(item)")
						case .failure(let error):
                            Log.error("保存失败: \(error.localizedDescription)")
						}
					}
				}
			}
		}
	}
	
	
	// 删除指定的 RingtoneCloudData
	func deleteCloudServer(_ serverID: String, completion: @escaping (Error?) -> Void) {
		// 调用数据库的 delete 方法删除记录
		database.delete(withRecordID: CKRecord.ID(recordName: serverID)) { (deletedRecordID, error) in
			Log.debug(deletedRecordID ?? "")
			completion(error)
		}
	}
    
    
    // 检查重复项并删除
    func removeDuplicates() {
        fetchPushServerModels { response in
            switch response {
            case .success(let models):
                var uniqueSet = Set<String>() // 存储唯一标识（key + url）
                var duplicates = [String]() // 存储重复项 ID
                
                for model in models {
                    let identifier = "\(model.key)-\(model.url)"
                    if uniqueSet.contains(identifier) {
                        duplicates.append(model.id)
                    } else {
                        uniqueSet.insert(identifier)
                    }
                }
                
                // 批量删除重复项
                for duplicateID in duplicates {
                    self.deleteCloudServer(duplicateID) { error in
                        if let error = error {
                            Log.error("删除重复项失败: \(error.localizedDescription)")
                        } else {
                            Log.debug("成功删除重复项: \(duplicateID)")
                        }
                    }
                }
                
            case .failure(let error):
                Log.error("获取数据失败，无法检查重复: \(error.localizedDescription)")
            }
        }
    }
	
    
    func getUserId() async -> CKRecord.ID? {
        do{
            let user =  try await container.userRecordID()
            if  Defaults[.id].isEmpty{
                Defaults[.id] = user.recordName
            }
             return user
        }catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func updateUser(token:String) async {
        do{
            
            guard let user = await getUserId() else { return }
            let data =  try await publicDB.record(for: user)
            data["token"] = token
            let operation = CKModifyRecordsOperation(recordsToSave: [ data], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.modifyRecordsResultBlock  = {  results in
                switch results {
                case .success(let data):
                    debugPrint(data)
                case .failure(let err):
                    debugPrint(err.localizedDescription)
                }
            }
            publicDB.add(operation)
        }catch{
            debugPrint(error.localizedDescription)
        }
        
    }
    
	
	
	
}
