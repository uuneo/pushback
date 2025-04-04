//
//  RealmConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

@_exported import RealmSwift
import Foundation

let kRealmDefaultConfiguration = {
	let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BaseConfig.groupName)

#if DEBUG
	Logger.shared.level = .debug
#endif
    return Realm.Configuration(
		fileURL: groupUrl?.appendingPathComponent(BaseConfig.realmName),
		schemaVersion: 35,
		migrationBlock: { _, oldSchemaVersion in
			if oldSchemaVersion < 1 { }
		}

	)
}()

