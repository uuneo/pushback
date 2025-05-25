//
//  RealmConfig.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

@_exported import RealmSwift
import Foundation


let kRealmDefaultConfiguration = {

    return Realm.Configuration(
		fileURL: CONTAINER?.appendingPathComponent(BaseConfig.realmName),
		schemaVersion: 57,
		migrationBlock: { _, oldSchemaVersion in
			if oldSchemaVersion < 1 { }
		}

	)
}()



 
