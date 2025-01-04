//
//  LocalKeys.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

@_exported import Defaults

extension Defaults.Keys {
	static let deviceToken = Key<String>(BaseConfig.deviceToken, default: "", suite: DEFAULTSTORE)
	static let servers = Key<[PushServerModel]>(BaseConfig.server, default: [], suite: DEFAULTSTORE)
	static let appIcon = Key<AppIconEnum>(BaseConfig.activeAppIcon, default: .pushback, suite: DEFAULTSTORE)
	static let cryptoConfig = Key<CryptoModel>(BaseConfig.CryptoSettingFields, default: CryptoModel.data, suite: DEFAULTSTORE)
	static let badgeMode = Key<BadgeAutoMode>(BaseConfig.badgemode, default: .auto, suite: DEFAULTSTORE)
	static let sound = Key<SoundDefault>(BaseConfig.defaultSound, default: SoundDefault.def, suite: DEFAULTSTORE)
	static let firstStart = Key<Bool>(BaseConfig.firstStartApp,default: true, suite: DEFAULTSTORE)
	static let photoName = Key<String>(BaseConfig.customPhotoName, default: BaseConfig.photoName, suite: DEFAULTSTORE)
	static let messageExpiration = Key<ExpirationTime>(BaseConfig.messageExpirtion,default: .forever,suite: DEFAULTSTORE)
	static let defaultBrowser = Key<DefaultBrowserModel>(BaseConfig.defaultBrowser,default: .safari, suite:DEFAULTSTORE)
	static let cacheSize = Key<CacheSizeLimit>(BaseConfig.cacheSizeLimit, default: .five, suite: DEFAULTSTORE)
	static let images = Key<[ImageModel]>(BaseConfig.imagesLocalMap, default: [], suite: DEFAULTSTORE )
	static let imageSaveDays = Key<ExpirationTime>(BaseConfig.imageSaveDays,default: .forever, suite: DEFAULTSTORE)
	static let autoSaveImageToAlbum = Key<Bool>(BaseConfig.autoSaveImageAlbum, default: false, suite: DEFAULTSTORE)

}





