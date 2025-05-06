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
import SwiftyJSON




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
        let data:Data?
        switch mode {
        case .CBC, .ECB:
            data = commonCryptoEncrypt(data: plaintext, operation: CCOperation(kCCEncrypt))
        case .GCM:
            data = gcmEncrypt(data: plaintext)
        }
            /// .replacingOccurrences(of: "+", with: "%2B")
        return data?.base64EncodedString()
    }

	func decrypt(_ ciphertext: Data) -> String? {
		switch mode {
		case .CBC, .ECB:
			guard let decryptedData = commonCryptoEncrypt(data: ciphertext, operation: CCOperation(kCCDecrypt)) else { return nil }
			return String(data: decryptedData, encoding: .utf8)
		case .GCM:
			guard let decryptedData = gcmDecrypt(data: ciphertext) else { return nil }
			return String(data: decryptedData, encoding: .utf8)
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

