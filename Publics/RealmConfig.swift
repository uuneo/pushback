//
//  RealmConfig.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

@_exported import RealmSwift
import Foundation

let kRealmDefaultConfiguration = {
	let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)
	
	let fileUrl = groupUrl?.appendingPathComponent(BaseConfig.realmName)
	
	
	let config = Realm.Configuration(
		fileURL: fileUrl,
		schemaVersion: 27,
		migrationBlock: { _, oldSchemaVersion in
			// We haven’t migrated anything yet, so oldSchemaVersion == 0
			if oldSchemaVersion < 1 {
				// Nothing to do!
				// Realm will automatically detect new properties and removed properties
				// And will update the schema on disk automatically
			}
		}
	)
	return config
}()
