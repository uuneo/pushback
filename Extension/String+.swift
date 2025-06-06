//
//  String+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//
import SwiftUI
import CryptoKit

public func NSLocalizedString(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "", comment: String? = nil) -> String{
    NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment ?? "")
}

extension String: @retroactive Error {}



extension String{
    
    /// 移除 URL 的 HTTP/HTTPS 前缀
    func removeHTTPPrefix() -> String {
        return self.replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)
    }
    
    func hasHttp() -> Bool{ ["http", "https"].contains{ self.lowercased().hasPrefix($0) } }

    
    func sha256() -> String{
        // 计算 SHA-256 哈希值
        // 将哈希值转换为十六进制字符串
        guard let data = self.data(using: .utf8) else {
            return String(self.prefix(10))
        }
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}

