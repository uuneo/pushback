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
    
    public let dbQueue: DatabasePool
    public let localPath:URL
    
    private init() throws {
        let local = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pushback")
        guard let local = local else {
            throw NSError(domain: "App", code: 1, userInfo: [NSLocalizedDescriptionKey: "创建容器失败"])
        }
        let path = local.appendingPathComponent("pushback.sqlite", conformingTo: .database)
        self.localPath = path
        // DatabasePool 只在这里创建一次
        self.dbQueue = try DatabasePool(path: path.path)
    }
}
