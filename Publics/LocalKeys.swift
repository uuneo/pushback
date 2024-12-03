//
//  LocalKeys.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

@_exported import Defaults

extension Defaults.Keys {
	static let deviceToken = Key<String>(BaseConfig.deviceToken, default: "", suite: DEFAULTSTORE)
	static let servers = Key<[PushServerModal]>(BaseConfig.server, default: [], suite: DEFAULTSTORE)
	static let appIcon = Key<AppIconEnum>(BaseConfig.activeAppIcon, default: .def, suite: DEFAULTSTORE)
	static let cryptoConfig = Key<CryptoModal>(BaseConfig.CryptoSettingFields, default: CryptoModal.data, suite: DEFAULTSTORE)
	static let badgeMode = Key<BadgeAutoMode>(BaseConfig.badgemode, default: .auto, suite: DEFAULTSTORE)
	static let sound = Key<SoundDefault>(BaseConfig.defaultSound, default: SoundDefault.def, suite: DEFAULTSTORE)
	static let firstStart = Key<Bool>(BaseConfig.firstStartApp,default: true, suite: DEFAULTSTORE)
	static let photoName = Key<String>(BaseConfig.customPhotoName, default: BaseConfig.photoName, suite: DEFAULTSTORE)
	static let messageExpiration = Key<ExpirationTime>(BaseConfig.messageExpirtion,default: .forever,suite: DEFAULTSTORE)
	
}



func cryptoExampleHandler() -> String {
	let config = Defaults[.cryptoConfig]
	let servers = Defaults[.servers]
	
	let cipher = "AES.new(key, AES.MODE_\(config.mode.rawValue)\(config.mode == .ECB ?  "" : ", iv" ))"
	
	let paddedData = config.mode == .GCM ? "data.encode()" : "pad(data.encode(), AES.block_size)"
	
	let encryptedData = config.mode == .GCM ? "encrypted_data, tag = cipher.encrypt_and_digest(padded_data)" : "encrypted_data = cipher.encrypt(padded_data)"
	
	let encryptedDataReturn = config.mode == .GCM ? "iv + encrypted_data + tag" : "encrypted_data"
	
	let nonce = config.mode == .GCM ? "iv[:12]" : "iv"
	
	return """
 # Documentation: "https://pushback.uuneo.com/#/encryption"
 # python demo: \(String(localized: "使用AES加密数据，并发送到服务器"))
 # pip3 install pycryptodome
 
 import json
 import base64
 import requests
 from Crypto.Cipher import AES
 from Crypto.Util.Padding import pad
 
 def encrypt_aes_mode(data, key, iv):
     cipher = \(cipher)
     padded_data = \(paddedData)
     \(encryptedData)
     return \(encryptedDataReturn)
 
 
 # \(String(localized: "JSON数据"))
 json_string = json.dumps(\(BaseConfig.testData))
 
 # \(String(format: String(localized: "必须%d位"), Int(config.algorithm.name.suffix(3))! / 8))
 key = b"\(config.key)"
 # \(String(localized: "IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。"))
 iv= b"\(config.iv)"
 
 # \(String(localized: "加密"))
 encrypted_data = encrypt_aes_mode(json_string, key, \(nonce))
 
 # \(String(localized: "将加密后的数据转换为Base64编码"))
 encrypted_base64 = base64.b64encode(encrypted_data).decode()
 
 print("\(String(localized: "加密后的数据（Base64编码"))", encrypted_base64)
 
 deviceKey = '\(servers[0].key)'
 
 res = requests.get(f"\(servers[0].url)/{deviceKey}/test", params = {"ciphertext": encrypted_base64})
 
 print(res.text)
 """
}
