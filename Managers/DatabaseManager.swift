//
//  DatabaseManager.swift
//  pushback
//
//  Created by lynn on 2025/5/26.
//
import GRDB
import Foundation

public class DatabaseManager {
    
    public static let shared = try! DatabaseManager()

    
    public let dbPool: DatabasePool
    public let localPath:URL
    
    private init() throws {
        let local = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pushback")
        guard let local = local else {
            throw NSError(domain: "App", code: 1, userInfo: [NSLocalizedDescriptionKey: "创建容器失败"])
        }
        let path = local.appendingPathComponent("pushback.sqlite", conformingTo: .database)
        self.localPath = path
        // DatabasePool 只在这里创建一次
        self.dbPool = try DatabasePool(path: path.path)
        
        try Message.createInit(dbPool: dbPool)
        try ChatGroup.createInit(dbPool: dbPool)
        try ChatMessage.createInit(dbPool: dbPool)
        try ChatPrompt.createInit(dbPool: dbPool)
    }
    
    func checkDriveData(complete: @escaping (Bool) -> Void) {
        Task.detached(priority: .userInitiated) {
            do{
               
                let messages = try Self.shared.dbPool.read { db in
                    try Message.fetchAll(db)
                }
                
                let chatgroups = try Self.shared.dbPool.read { db in
                    try ChatGroup.fetchAll(db)
                }
                
                let chatMessages = try Self.shared.dbPool.read { db in
                    try ChatMessage.fetchAll(db)
                }
                
                let chatPrompts = try Self.shared.dbPool.read { db in
                    try ChatPrompt.fetchAll(db)
                }
                
                try self.dbPool.write { db in
                    try db.drop(table: Message.databaseTableName)
                    try db.drop(table: ChatGroup.databaseTableName)
                    try db.drop(table: ChatMessage.databaseTableName)
                    try db.drop(table: ChatPrompt.databaseTableName)
                    
                    db.clearSchemaCache()
                }
                
                try self.dbPool.vacuum()
                
                try Message.createInit(dbPool: self.dbPool)
                try ChatGroup.createInit(dbPool: self.dbPool)
                try ChatMessage.createInit(dbPool: self.dbPool)
                try ChatPrompt.createInit(dbPool: self.dbPool)
                
                try self.dbPool.write { db in
                    for message in messages {
                        try message.insert(db)
                    }
                    for chatgroup in chatgroups {
                        try chatgroup.insert(db)
                    }
                    for chatMessage in chatMessages{
                        try chatMessage.insert(db)
                    }
                    
                    for chatPrompt in chatPrompts{
                        try chatPrompt.insert(db)
                    }
                }
                
                try self.dbPool.vacuum()
                
                complete(true)
                
            }catch{
                debugPrint(error.localizedDescription)
                complete(false)
            }
        }
    }

}
