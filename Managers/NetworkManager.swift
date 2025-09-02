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


class NetworkManager: NSObject {

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
    func fetchVoid(url: String, method: requestMethod = .get, params: [String: Any] = [:]) async {
        _ = try? await self.fetch(url: url, method: method, params: params, timeout: 3)
    }
    
    /// 通用网络请求方法
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法（默认为 GET）
    ///   - params: 请求参数（支持 GET 查询参数或 POST body）
    /// - Returns: 返回泛型解码后的模型数据
    func fetch<T: Codable>(url: String, method: requestMethod = .get, params: [String: Any] = [:], headers:[String:String] = [:], timeout:Double = 30) async throws -> T {
        let data = try await self.fetch(url: url, method: method, params: params, headers: headers, timeout: timeout)
        // 尝试将响应的 JSON 解码为泛型模型 T
        do{
            let result = try JSONDecoder().decode(T.self, from: data)
            return result
        }catch{
            Log.debug(String(data: data, encoding: .utf8) ?? "")
            
            throw error
        }
        
    }
    
    func fetch(url: String, method: requestMethod = .get, params: [String: Any] = [:], headers:[String:String] = [:], timeout:Double = 30) async throws -> Data {
        
        // 尝试将字符串转换为 URL，如果失败则抛出错误
        guard var requestUrl = URL(string: url) else {
            throw "url error"
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
        request.setValue(self.customUserAgentDetailed(), forHTTPHeaderField: "User-Agent" )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization") 
        
        for (key,value) in headers{
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 如果是 POST 请求，将参数编码为 JSON 设置到 httpBody
        if method == .post && !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        request.timeoutInterval = timeout
        
        // 打印请求信息（用于调试）
        Log.debug(request)
       
        // 发起请求并等待响应（带有 30 秒超时）
        let data = try await session.data(for: request)
        
        

       return data
    }
   

    func customUserAgentDetailed() -> String {
        let info = Bundle.main.infoDictionary
        
        let appName     =  BaseConfig.appSymbol
        let appVersion  = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let buildNumber = info?["CFBundleVersion"] as? String ?? "0"
        
        let deviceModel = deviceIdentifier()
        let systemVer   = UIDevice.current.systemVersion
        
        let locale      = Locale.current
        let regionCode  = locale.region?.identifier ?? "XX"   // e.g. CN
        let language    = locale.language.languageCode?.identifier ?? "en" // e.g. zh
        
        return "\(appName)/\(appVersion) (Build \(buildNumber); \(deviceModel); iOS \(systemVer); \(regionCode)-\(language))"
    }

    private func deviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
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
            .map { "\($0.key.lowercased()):\($0.value.lowercased())" }
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

extension NetworkManager {

    /// 上传文件
    /// - Parameters:
    ///   - url: 接口地址
    ///   - method: 请求方法，默认为 POST
    ///   - fileData: 要上传的文件数据
    ///   - fileName: 文件名
    ///   - mimeType: 文件 MIME 类型
    ///   - params: 其他表单数据
    /// - Returns: 返回服务器响应的 Data
    func uploadFile(url: String,
                    method: requestMethod = .post,
                    fileData: Data,
                    fileName: String,
                    mimeType: String,
                    params: [String: Any] = [:]) async throws -> Data {
        
        guard let url = URL(string: url) else {
            throw "Invalid URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.method
        
        // 生成唯一的 boundary 字符串
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // 设置 Content-Type 为 multipart/form-data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(self.customUserAgentDetailed(), forHTTPHeaderField: "User-Agent")
        request.setValue(Defaults[.id], forHTTPHeaderField: "Authorization")
        
        // 生成表单数据
        var body = Data()
        
        // 添加普通表单字段（如果有的话）
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 添加文件字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 结束 boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 设置 HTTPBody
        request.httpBody = body
        
        // 设置请求超时时间
        request.timeoutInterval = 60
        
        // 打印请求信息（用于调试）
        Log.debug(request)
        
        // 发送请求并等待响应
        let data = try await session.data(for: request)
        
        return data
    }
}
