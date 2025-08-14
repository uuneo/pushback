//
//  cryptoManager.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import Foundation
import CommonCrypto
import CryptoKit
import Defaults
import Encryptor

// MARK: - CryptoMode

enum CryptoMode: String, Codable,CaseIterable, RawRepresentable {
    
    case CBC, ECB, GCM
    var padding: String {
        self == .GCM ? "Space" : "PKCS7"
    }
    
    var Icon:String{
        switch self{
        case .CBC: "circle.grid.cross.left.filled"
        case .ECB: "circle.grid.cross.up.filled"
        case .GCM: "circle.grid.cross.right.filled"
        }
    }
    
    
}

enum CryptoAlgorithm: Int, Codable, CaseIterable,RawRepresentable {
    case AES128 = 16 // 16 bytes = 128 bits
    case AES192 = 24 // 24 bytes = 192 bits
    case AES256 = 32 // 32 bytes = 256 bits
    
    var name:String{
        switch self {
        case .AES128: "AES128"
        case .AES192: "AES192"
        case .AES256: "AES256"
        }
    }
    
    var Icon:String{
        switch self{
        case .AES128: "gauge.low"
        case .AES192: "gauge.medium"
        case .AES256: "gauge.high"
        }
    }
    
    
    
}

struct CryptoModelConfig: Identifiable, Equatable, Codable{
    var id: String = UUID().uuidString
    var algorithm: CryptoAlgorithm
    var mode: CryptoMode
    var key: String
    var iv: String
    
    static let data = CryptoModelConfig(algorithm: .AES256,
                                        mode: .GCM,
                                        key: "ToBeOrNotToBeThatIsTheRealDomogo",
                                        iv: "DreamBigWorkHard")
    
    static func generateRandomString(_ length: Int = 16) -> String {
        Domap.generateRandomString(length)
    }
    
    static func creteNewModel() -> Self{
        CryptoModelConfig(id: UUID().uuidString, algorithm: .AES256,
                          mode: .GCM,
                          key: Self.generateRandomString(32),
                          iv: Self.generateRandomString())
    }
    
    static func ==(lls:CryptoModelConfig, rls: CryptoModelConfig) -> Bool{
        return lls.algorithm == rls.algorithm &&
        lls.mode == rls.mode &&
        lls.key == rls.key &&
        lls.iv == rls.iv
    }
    
}
///  pb://crypto?text=eIxk2XSXdVeC3zsMwmlJevVaXGncCTiUHg5lLiK0S2sG3QLuGMU

extension [CryptoModelConfig]{
    func config(_ number: Int? = nil) -> CryptoModelConfig{
        if let number = number, number <= self.count{
            return self[number - 1]
        }
        if let item = self.first{
            return item
        }
        return CryptoModelConfig.data
    }
}

extension CryptoModelConfig {
    func obfuscator() -> String? {
        Domap.obfuscator(m: mode.rawValue, k: key, iv: iv)
    }
    
    init?(inputText: String){
        guard let (mode, key, iv) = Domap.deobfuscator(result: inputText),
              let mode = CryptoMode(rawValue: mode),
              let algorithm = CryptoAlgorithm(rawValue: key.count)
        else { return nil}
        self.init(algorithm: algorithm, mode: mode, key: key, iv: iv)
    }
    
    func encrypt(inputData: Data) -> Data?{
        let manager = CryptoManager(self)
        return manager.encrypt(inputData: inputData)
    }
    
    func decrypt(inputData: Data) -> Data? {
        let manager = CryptoManager(self)
        return manager.decrypt(inputData: inputData)
    }
    
}

public enum Domap{
    
    public static func set(_ input: String) -> String? {
        let len = input.utf8.count
        guard len == 16 || len == 24 || len == 32 else { return nil }
        
        let encryptor = Encryptor_create()
        
        let inputCString = input.cString(using: .utf8)!
        // 结果缓冲区
        var outputBuffer = [CChar](repeating: 0, count: len + 1)
        
        let result = encryptor.encrypt(inputCString, &outputBuffer)
        if result == 0 {
            let outputString = outputBuffer
                .prefix { $0 != 0 }            // 截取到 null 终止
                .map { UInt8(bitPattern: $0) } // 转换 Int8 -> UInt8
            let result = String(decoding: outputString, as: UTF8.self)
            return result
        } else {  return nil }
    }
    
    public static func get(_ input: String) -> String? {
        
        let len = input.utf8.count
        guard len == 16 || len == 24 || len == 32 else { return nil }
        
        let encryptor = Encryptor_create()
        let inputCString = input.cString(using: .utf8)!
        var outputBuffer = [CChar](repeating: 0, count: len + 1)
        
        let result = encryptor.decrypt(inputCString, &outputBuffer)
        if result == 0 {
            let outputString = outputBuffer
                .prefix { $0 != 0 }            // 截取到 null 终止
                .map { UInt8(bitPattern: $0) } // 转换 Int8 -> UInt8
            let result = String(decoding: outputString, as: UTF8.self)
            return result
        } else {
            print("解密失败")
            return nil
        }
    }
    
    public static func generateRandomString(_ length: Int = 16) -> String {
        // 创建可用字符集（大写、小写字母和数字）
        let charactersArray = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        
        return String(Array(1...length).compactMap { _ in charactersArray.randomElement() })
    }
    
    public static func calculateInsertPositions(for string: String) -> (Int, Int, Int) {
        let hashValue = string.count - 3
        let pos1 = abs(hashValue / 3 + 1)
        let pos2 = abs(hashValue / 2 - 2)
        let pos3 = abs(hashValue - pos1)
        return (pos1, pos2, pos3)
    }
    
    public static func obfuscator(m: String, k: String, iv: String) -> String? {
        
        guard iv.count == 16, k.count >= 16, m.count == 3 else { return nil }
        
        guard let ivTem = Self.set(iv),
              let keyTem = Self.set(k) else { return nil}
        
        let position: (Int, Int, Int) = Self.calculateInsertPositions(for: ivTem + keyTem + m)
        
        var result = ivTem + keyTem
        let inserts = Array(m.lowercased())
        let positions = [position.0, position.1, position.2].sorted()
        
        // 从后往前插入，防止位置错乱
        for i in (0..<3).reversed() {
            let idx = result.index(result.startIndex, offsetBy: positions[i])
            result.insert(inserts[i], at: idx)
        }
        
        return String(result.reversed())
    }
    
    public static func deobfuscator(result: String) -> (String, String, String)? {
        
        let result = String(result.reversed())
        guard result.count > 20 else { return nil}
        
        let position: (Int, Int, Int) = Self.calculateInsertPositions(for: result)
        
        var original = result
        let positions = [position.0, position.1, position.2].sorted()
        var inserts = ""
        
        // 从前往后移除字符（位置会因为删除而变化）
        for i in 0..<3 {
            let index = original.index(original.startIndex, offsetBy: positions[i])
            inserts.append(original[index])
            original.remove(at: index)
        }
        let startIndex = original.startIndex
        let splitIndex = original.index(startIndex, offsetBy: 16)
        
        let ivDataTem = String(original[startIndex..<splitIndex])
        let keyDataTem = String(original[splitIndex...])
        
        guard let ivData = Self.get(ivDataTem),
              let keyData = Self.get(keyDataTem) else { return nil}
        
        
        inserts = inserts.uppercased()
        
        return (inserts, keyData, ivData)
        
    }
    
    
}




final class CryptoManager {
	
	private let algorithm: CryptoAlgorithm
	private let mode: CryptoMode
	private let key: Data
	private let iv: Data


	init(_ data: CryptoModelConfig) {
		self.key = data.key.data(using: .utf8)!
		self.iv = data.iv.data(using: .utf8)!
		self.mode = data.mode
		self.algorithm = data.algorithm
	}

    
    // MARK: - Public Methods
	func encrypt(_ plaintext: String) -> String? {
		guard let plaintextData = plaintext.data(using: .utf8) else { return nil }
        return self.encrypt(plaintextData)
	}
    
    func encrypt(_ plaintext: Data) -> String? {
        let data:Data? = self.encrypt(inputData: plaintext)
            /// .replacingOccurrences(of: "+", with: "%2B")
        return data?.base64EncodedString()
    }
    
    func decrypt(_ ciphertext: Data) -> String? {
        if let decryptedData = self.decrypt(inputData: ciphertext){
            return String(data: decryptedData, encoding: .utf8)
        }
        return nil
    }
    
    func encrypt(inputData: Data) -> Data?{
        let data:Data?
        switch mode {
        case .CBC, .ECB:
            data = commonCryptoEncrypt(data: inputData, operation: CCOperation(kCCEncrypt))
        case .GCM:
            data = gcmEncrypt(data: inputData)
        }
        return data
    }
    
    func decrypt(inputData: Data) -> Data? {
        switch mode {
        case .CBC, .ECB:
            return commonCryptoEncrypt(data: inputData, operation: CCOperation(kCCDecrypt))
        case .GCM:
            return gcmDecrypt(data: inputData)
        }
        
    }
    
	// MARK: - Private Methods
	// CommonCrypto (CBC/ECB) Encryption/Decryption
	private func commonCryptoEncrypt(data: Data, operation: CCOperation) -> Data? {
		let algorithm = CCAlgorithm(kCCAlgorithmAES) // AES algorithm
		let options = mode == .CBC ? CCOptions(kCCOptionPKCS7Padding) : CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode)

		var numBytesEncrypted: size_t = 0
		let dataOutLength = data.count + kCCBlockSizeAES128
		var dataOut = Data(count: dataOutLength)
		
		let cryptStatus = dataOut.withUnsafeMutableBytes { dataOutBytes in
			data.withUnsafeBytes { dataInBytes in
				key.withUnsafeBytes { keyBytes in
					iv.withUnsafeBytes { ivBytes in
						CCCrypt(operation,
								algorithm, // AES algorithm
								options,
								keyBytes.baseAddress!, key.count, // Key length based on key.count
								mode == .CBC ? ivBytes.baseAddress : nil, // Use IV for CBC, nil for ECB
								dataInBytes.baseAddress!, data.count,
								dataOutBytes.baseAddress!, dataOutLength,
								&numBytesEncrypted)
					}
				}
			}
		}

		if cryptStatus == kCCSuccess {
			return dataOut.prefix(numBytesEncrypted)
		}
		return nil
	}

	// CryptoKit (GCM) Encryption
	private func gcmEncrypt(data: Data) -> Data? {
		let symmetricKey = SymmetricKey(data: key)
		
		do {
			let nonce = try AES.GCM.Nonce(data: iv.prefix(12))
			let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
			return nonce + sealedBox.ciphertext + sealedBox.tag // Nonce + Ciphertext + Tag
		} catch {
            Log.error("GCM Encryption error: \(error)")
			return nil
		}
	}

	// CryptoKit (GCM) Decryption
	private func gcmDecrypt(data: Data) -> Data? {
		let nonceSize = 12
		let tagSize = 16

		guard data.count > nonceSize + tagSize else { return nil }

		let symmetricKey = SymmetricKey(data: key)
		let nonce = try? AES.GCM.Nonce(data: data.prefix(nonceSize))
		let ciphertext = data.dropFirst(nonceSize).dropLast(tagSize)
		let tag = data.suffix(tagSize)

		do {
			let sealedBox = try AES.GCM.SealedBox(nonce: nonce!, ciphertext: ciphertext, tag: tag)
			return try AES.GCM.open(sealedBox, using: symmetricKey)
		} catch {
            Log.error("GCM Decryption error: \(error)")
			return nil
		}
	}
	

}

