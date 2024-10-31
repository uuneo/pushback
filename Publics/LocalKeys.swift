//
//  LocalKeys.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

import Defaults


extension Defaults.Keys {
	static let deviceToken = Key<String>(BaseConfig.deviceToken, default: "", suite: DEFAULTSTORE)
	static let servers = Key<[PushServerModal]>(BaseConfig.server, default: PushServerModal.serverArr, suite: DEFAULTSTORE)
	static let appIcon = Key<AppIconEnum>(BaseConfig.activeAppIcon, default: .def, suite: DEFAULTSTORE)
	static let cryptoConfig = Key<CryptoModal>(BaseConfig.CryptoSettingFields, default: CryptoModal.data, suite: DEFAULTSTORE)
	static let isMessageStorage = Key<Bool>(BaseConfig.isMessageStorage, default: true, suite: DEFAULTSTORE)
	static let badgeMode = Key<BadgeAutoMode>(BaseConfig.badgemode, default: .auto, suite: DEFAULTSTORE)
	static let sound = Key<String>(BaseConfig.defaultSound, default: "silence", suite: DEFAULTSTORE)
	static let firstStart = Key<Bool>(BaseConfig.firstStartApp,default: true, suite: DEFAULTSTORE)
	static let photoName = Key<String>(BaseConfig.customPhotoName, default: "pushback.", suite: DEFAULTSTORE)

}
