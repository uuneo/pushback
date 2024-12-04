//
//  File name:     NetworkManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/4.
	

import Foundation
import UIKit
import CommonCrypto

class NetworkManager {
	
	enum requestMethod:String{
		case get = "GET"
		case post = "POST"
		
		var method:String{
			self.rawValue
		}
	}
	
	/// Request Data
	func fetch<T: Codable>(url: String, method: requestMethod = .get, params: [String: Any]? = nil) async throws -> T? {
		// 根据请求方法和参数构建请求 URL
		var requestUrl = URL(string: url)
		
		// 如果是 GET 请求且有参数，将参数拼接到 URL 上
		if method == .get, let params = params {
			var urlComponents = URLComponents(string: url)
			urlComponents?.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
			requestUrl = urlComponents?.url
		}
		
		
		// 检查 URL 是否有效
		guard let finalUrl = requestUrl else { return nil }
		
		// 创建 URLRequest
		var request = URLRequest(url: finalUrl)
		request.httpMethod = method.method
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue(self.generateUserAgent(), forHTTPHeaderField: "User-Agent")
		request.setValue(sign(url: url, params: params, key: BaseConfig.signKey), forHTTPHeaderField: "X-Signature")
		
		// 如果是 POST 请求且有参数，将参数编码为 JSON 并设置为请求体
		if method == .post, let params = params {
			request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
		}
		
		// 发送请求并解析响应
		let (data, _) = try await URLSession.shared.data(for: request)
		let result = try JSONDecoder().decode(T.self, from: data)
		return result
	}
	
	
	func sign(url: String, method: requestMethod = .get, params: [String: Any]?, key:String) -> String{
		
		// 使用 HMAC-SHA256 对 JSON 数据进行签名
		let keyData = key.data(using: .utf8)!
		var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		
		var newParams:[String: Any] = [:]
		newParams["url"] = url
		newParams["method"] = method.method
		if let params = params{
			for (key,value) in params{
				newParams[key] = value
			}
		}
		
		let paramsStr = newParams.sorted(by: { $0.key < $1.key}).map({"\($0.key):\($0.value)"}).joined(separator: ",")
		guard let strData = paramsStr.data(using: .utf8) else {
			return ""
		}
		keyData.withUnsafeBytes { keyBytes in
			strData.withUnsafeBytes { dataBytes in
				CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyBytes.count, dataBytes.baseAddress, dataBytes.count, &hmac)
			}
		}
		let hmacData = Data(hmac)
		let signString = hmacData.map { String(format: "%02x", $0) }.joined()
		return signString
		
	}
	
	
	func generateUserAgent() -> String {
		// 获取设备信息
		let deviceModel = UIDevice.current.model   			// 设备型号，例如 iPhone, iPad, MacBook
		let systemVersion = UIDevice.current.systemVersion  // 操作系统版本，如 16.0
		let deviceName = UIDevice.current.name     			// 设备名称，如 John's iPhone
		
		// 获取应用信息
		let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownApp"
		let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
		let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
		
		
		// 生成 User-Agent 字符串
		let userAgent = "Mozilla/5.0 (\(deviceModel); U; \(deviceModel) \(systemVersion); \(deviceName) Build/\(appBuild)) \(appName)/\(appVersion)"
		
		return userAgent
	}
}
