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

#if DEBUG
	Logger.shared.level = .info
#endif
	let config = Realm.Configuration(
		fileURL: groupUrl?.appendingPathComponent(BaseConfig.realmName),
		schemaVersion: 32,
		migrationBlock: { _, oldSchemaVersion in
			if oldSchemaVersion < 1 { }
		}

	)
	return config
}()
