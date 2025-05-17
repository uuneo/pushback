//
//  File name:     NetworkManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/4.
	
import UIKit
import Foundation
import CommonCrypto
import Defaults



class NetworkManager {

    let session = URLSession(configuration: .default)

	enum requestMethod:String{
		case get = "GET"
		case post = "POST"
		
		var method:String{
			self.rawValue
		}
	}
    
    struct EmptyResponse: Codable {}
    
    
    /// 无返回值
    func fetchVoid(url: String, method: requestMethod = .get, params: [String: Any] = [:]) {
        Task.detached(priority: .background) {
            _ = try? await self.fetch(url: url, method: method, params: params)
        }
    }
    
    /// 通用网络请求方法
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（默认为 GET）
    ///   - params: 请求参数（支持 GET 查询参数或 POST body）
    /// - Returns: 返回泛型解码后的模型数据
    func fetch<T: Codable>(url: String, method: requestMethod = .get, params: [String: Any] = [:]) async throws -> T? {
        let data = try await self.fetch(url: url, method: method, params: params)
        // 尝试将响应的 JSON 解码为泛型模型 T
        let result = try JSONDecoder().decode(T.self, from: data)
        return result
        
    }
    
    func fetch(url: String, method: requestMethod = .get, params: [String: Any] = [:]) async throws -> Data {
        
        // 尝试将字符串转换为 URL，如果失败则抛出错误
        guard var requestUrl = URL(string: url) else {
            throw StringError("url error")
        }

        // 如果是 GET 请求并且有参数，将参数拼接到 URL 的 query 中
        if method == .get && !params.isEmpty {
            if var urlComponents = URLComponents(string: url) {
                urlComponents.queryItems = params.map {
                    URLQueryItem(name: $0.key, value: "\($0.value)")
                }
                if let composedUrl = urlComponents.url {
                    requestUrl = composedUrl
                }
            }
        }

        // 构造 URLRequest 请求对象
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.method  // .get 或 .post
        request.setValue( sign(url: url, params: params, key: BaseConfig.signKey), forHTTPHeaderField: "X-Signature" )
        request.setValue(self.generateCustomUserAgent(), forHTTPHeaderField: "User-Agent" )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")
        
        // 如果是 POST 请求，将参数编码为 JSON 设置到 httpBody
        if method == .post && !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        request.timeoutInterval = 30
        
        // 打印请求信息（用于调试）
        Log.debug(request)
       
        // 发起请求并等待响应（带有 30 秒超时）
        let data = try await session.data(for: request)

       return data
    }
    
    func generateCustomUserAgent() -> String {
       
        // 获取设备信息
        let device = UIDevice.current
        let systemName = device.systemName      // iOS
        let systemVersion = device.systemVersion // 系统版本
        let model = device.model                 // 设备型号 (例如 iPhone, iPad)
        
        // 获取应用信息
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        // 自定义User-Agent字符串
        let userAgent = "\(appName)/\(appVersion) (\(model); \(systemName) \(systemVersion); Build/\(buildVersion))"
        
        return userAgent
    }
    
    
    /// 扁平化嵌套参数
    /// - Example:
    /// Input: [user: ["name": "Tom", "info": ["age": 20]]]
    /// Output: ["user.name": "Tom", "user.info.age": "20"]
    func flattenParams(_ params: [String: Any], prefix: String = "") -> [String: String] {
        var result: [String: String] = [:]

        for (key, value) in params {
            let newKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            
            if let dict = value as? [String: Any] {
                // 递归处理子字典
                result.merge(flattenParams(dict, prefix: newKey)) { $1 }
            } else if let array = value as? [Any] {
                for (index, item) in array.enumerated() {
                    let arrayKey = "\(newKey)[\(index)]"
                    if let subDict = item as? [String: Any] {
                        result.merge(flattenParams(subDict, prefix: arrayKey)) { $1 }
                    } else {
                        result[arrayKey] = "\(item)"
                    }
                }
            } else {
                result[newKey] = "\(value)"
            }
        }

        return result
    }
	
    /// 使用 HMAC-SHA256 生成签名字符串
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（GET/POST）
    ///   - params: 请求参数字典
    ///   - key: 用于 HMAC 签名的密钥
    /// - Returns: 返回十六进制的签名字符串
    func sign(url: String, method: requestMethod = .get, params: [String: Any] = [:], key: String) -> String {
        // 将密钥转为 Data 格式
        guard let keyData = key.data(using: .utf8) else { return "" }
        
        // 存储 HMAC 结果的 buffer
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        // 将 URL 和方法也作为参数的一部分参与签名
        var newParams: [String: Any] = [
            "url": url,
            "method": method.method
        ]
        
        // 合并参数字典
        for (key, value) in params {
            newParams[key] = value
        }

        // 扁平化嵌套参数
        let flatParams = flattenParams(newParams)

        // 对参数字典按 key 升序排序，然后拼接成字符串：key1:value1,key2:value2,...
        let paramsStr = flatParams
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")

        // 将参数字符串转为 Data，如果失败则返回空字符串
        guard let strData = paramsStr.data(using: .utf8) else {
            return ""
        }

        // 使用 CCHmac 进行 HMAC-SHA256 签名
        keyData.withUnsafeBytes { keyBytes in
            strData.withUnsafeBytes { dataBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress,
                    keyBytes.count,
                    dataBytes.baseAddress,
                    dataBytes.count,
                    &hmac
                )
            }
        }

        // 将结果转为十六进制字符串
        let hmacData = Data(hmac)
        let signString = hmacData.map { String(format: "%02x", $0) }.joined()
        
        return signString
    }

    func appendQueryParameter(to urlString: String, key: String, value: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: key, value: value))
        components.queryItems = queryItems

        return components.url?.absoluteString
    }
}
