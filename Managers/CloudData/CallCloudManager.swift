//
//  CallCloudManager.swift
//  pushme
//
//  Created by lynn on 2025/6/17.
//

import Foundation
import CloudKit
import Defaults


final class CallCloudManager{
    
    static let shared = CallCloudManager()
    
    private init() {}
    private let container = CKContainer(identifier: BaseConfig.icloudName)
    
    private var database: CKDatabase {
        container.publicCloudDatabase
    }
    private let recordType = "Calls"
    private let numberType = "UniqueNumber"
    
    func user(id: String) async -> CKRecord?{
        guard id.count > 0 else { return nil }
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await database.record(for: recordID)
            return record
        }catch{
            debugPrint(error)
            return nil
        }
    }
    
    func downloadUser(id: String) async -> CallUser?{
        guard id.count > 0 else { return nil }
        if let call = await self.user(id: id){
            return call.toCallUser()
        }
        return nil
    }
    
    
    func vercaller(id: String) async -> Bool{
        if let _ =  await user(id: id){ return false }else{
            return true
        }
    }
    
    func queryCaller(caller: String) async -> CallUser?{
        let users = await self.users(caller: caller)
        return users.first?.toCallUser()
    }
    
    func users(caller: String) async -> [CKRecord]{
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "caller == %@", caller))
        do {
            // 直接使用 async 方法查询
            let (records, _) = try await database.records(matching: query)
            
            // 返回查询到的记录
            let datas = records.compactMap { (_, result) -> CKRecord? in
                switch result {
                case .success(let record):
                    return record
                case .failure(let error):
                    Log.error("获取单个记录失败: \(error.localizedDescription)")
                    return nil
                }
            }
            return datas
        } catch {
            Log.error("查询失败: \(error.localizedDescription)")
            return []
        }
    }
    
    private func add(_ call: CallUser) async throws {
        
        guard  let record = call.toRecord(recordType: recordType)else{
            throw SaveError.format
        }
        
        var saveRecords:[CKRecord] = [record]
        
        
        if !call.caller.isEmpty{
            let numberId = CKRecord.ID(recordName: call.caller)
            saveRecords.append(CKRecord(recordType: numberType, recordID: numberId))
        }
        
        try await performAtomicSave(saveRecords: saveRecords, deleteRecordIDs: [])
        
    }
    
    private func update(_ call: CallUser, data: CKRecord, avatar:Bool = false) async throws{
        
        
        var saveRecords:[CKRecord] = []
        var deleteRecords:[CKRecord.ID] = []
        
        
        let old = data["caller"] as? String
        
        if  call.caller != old, !call.caller.isEmpty {
            
            let recordIdNew = CKRecord.ID(recordName: call.caller)
            let record = CKRecord(recordType: numberType, recordID: recordIdNew)
            saveRecords.append(record)
            
            if let old, !old.isEmpty{
                let recordId = CKRecord.ID(recordName: old)
                deleteRecords.append(recordId)
            }
            
            
            data.set(call.caller, forKey: "caller")
        }
        
        data.set(call.name, forKey: "name")
        data.set(call.deviceToken, forKey: "deviceToken")
        data.set(call.voipToken, forKey: "voipToken")
        
        if avatar, let url = call.avatar, FileManager.default.fileExists(atPath:  url.path()){
            data["avatar"] = CKAsset(fileURL: url)
        }
        
        saveRecords.append(data)
        
        try await performAtomicSave(saveRecords: saveRecords, deleteRecordIDs: deleteRecords)
      
    }
    
    
    private func performAtomicSave( saveRecords: [CKRecord], deleteRecordIDs: [CKRecord.ID] ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: saveRecords, recordIDsToDelete: deleteRecordIDs)
            
            operation.savePolicy = .allKeys
            operation.isAtomic = true // ✅ 原子操作，全部成功或全部失败

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            database.add(operation)
        }
    }
    
    func save(_ call: CallUser, avatar:Bool = false) async -> Bool{
        
        var result = call
        
        if result.caller.count < 3 {  result.caller = "" }
        
        if result.id == ""{
            result.id = KeychainHelper.shared.getDeviceID()
        }
        
        
        let data = await self.user(id: result.id)
        
        do{
            if let data = data {
                try await self.update(result, data: data, avatar: avatar)
                
            }else{
                try  await self.add(result)
            }
            return true
        }catch{
            return false
        }
        
        
    }
    
}

enum SaveError: Error{
    case unique
    case ok
    case save
    case format
    case update
    case delete
}



struct CallUser: Identifiable, Codable, Equatable {
    var id: String
    var avatar: URL?
    var name:String
    var caller: String
    var deviceToken:String
    var voipToken:String
    var voip: Int
    
    static let `default` = CallUser(id: Defaults[.id], name: "", caller: "", deviceToken: "", voipToken: "", voip: 1)
    
    func toRecord(recordType: String) -> CKRecord?{
        
        let recordID = CKRecord.ID(recordName: self.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        if let avatar = avatar, FileManager.default.fileExists(atPath:  avatar.path()){
            record["avatar"] = CKAsset(fileURL: avatar)
        }
        record.set(self.name, forKey: "name")
        record.set(self.caller, forKey: "caller")
        record.set(self.deviceToken, forKey: "deviceToken")
        record.set(self.voipToken, forKey: "voipToken")
        record.set(self.voip, forKey: "voip")
        
        return record
    }
}

extension CallUser: Defaults.Serializable{}
extension Defaults.Keys{
    static let user = Key<CallUser>("CallUser",default: CallUser.default)
    static let turnId = Key<String>("CloudflareId",default: "", iCloud: true)
    static let turnToken = Key<String>("CloudflareApiToken",default: "", iCloud: true)
}


extension CKRecord{
    func toCallUser() -> CallUser? {
        guard let name =  self["name"] as? String ,
              let caller =  self["caller"] as? String ,
              let deviceToken = self["deviceToken"] as? String,
              let voipToken =  self["voipToken"] as? String,
              let voip = self["voip"] as? Int else { return nil }
        
        let avatar = self["avatar"] as? CKAsset
        
        return CallUser(id: self.recordID.recordName,
                        avatar: avatar?.fileURL,
                        name: name, caller: caller,
                        deviceToken: deviceToken, voipToken: voipToken,voip: voip)
    }
}




extension CKRecord {
    func set<T>(_ value: T?, forKey key: String) {
        if let v = value as? CKRecordValue {
            self[key] = v
        }
    }
}
