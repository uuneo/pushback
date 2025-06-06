//
//  Equatable+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//

import SwiftUI


extension Encodable {
    func toEncodableDictionary() -> [String: Any]? {
        // 1. 使用 JSONEncoder 将结构体编码为 JSON 数据
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        // 2. 使用 JSONSerialization 将 JSON 数据转换为字典
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}
