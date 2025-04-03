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

	private var session = URLSession(configuration: .default)

	enum requestMethod:String{
		case get = "GET"
		case post = "POST"
		
		var method:String{
			self.rawValue
		}
	}
	
	/// Request Data
	func fetch<T: Codable>(url: String, method: requestMethod = .get, params: [String: Any] = [:]) async throws -> T? {
		// 根据请求方法和参数构建请求 URL
		guard var requestUrl = URL(string: url) else {
			throw StringError("url error")
		}

		// 如果是 GET 请求且有参数，将参数拼接到 URL 上
		if method == .get  && !params.isEmpty{
			if var urlComponents = URLComponents(string: url){
				urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
				if let requestUrl1 = urlComponents.url{
					requestUrl = requestUrl1
				}

			}

		}
		// 创建 URLRequest
		var request = URLRequest(url: requestUrl)
		request.httpMethod = method.method
		request.setValue(sign(url: url, params: params, key: BaseConfig.signKey), forHTTPHeaderField: "X-Signature")

		// 如果是 POST 请求且有参数，将参数编码为 JSON 并设置为请求体
		if method == .post  && !params.isEmpty {
			request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
		}
        
        Log.debug(request)

		// 发送请求并解析响应
		let data = try await session.data(for: request,timeout: 30)
		let result = try JSONDecoder().decode(T.self, from: data)
		return result
	}
	
	
	func sign(url: String, method: requestMethod = .get, params: [String: Any] = [:], key:String) -> String{

		// 使用 HMAC-SHA256 对 JSON 数据进行签名
		let keyData = key.data(using: .utf8)!
		var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		
		var newParams:[String: Any] = ["url": url, "method": method.method]
		for (key,value) in params{
			newParams[key] = value
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

}
