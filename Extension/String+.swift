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
    
    var trimmingSpaceAndNewLines: String{
        self.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }
    
    func avatarImage(size: CGFloat = 300, padding: CGFloat = 16) -> UIImage? {
        guard let textColor = self.trimmingSpaceAndNewLines
            .decomposeStringColor() else { return nil }
        
        let singleEmoji = textColor.text.first?.isEmoji ?? false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let backgroundColor: UIColor = singleEmoji ? .clear : textColor.color
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            backgroundColor.setFill()
            context.cgContext.fillEllipse(in: rect)
            
            // 可用绘图区域为去除 padding 后的部分
            let availableRect = rect.insetBy(dx: padding, dy: padding)
            
            let fontSize = availableRect.height * (singleEmoji ? 1 : 0.85)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = textColor.text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            )
            
            textColor.text.draw(at: textOrigin, withAttributes: attributes)
        }
    }

    
    func decomposeStringColor(_ defaultColor:UIColor = .systemBlue) -> (text: String, color: UIColor)?{
        let input = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // 确保字符串至少有一个字符作为文本
        guard input.count >= 1 else { return nil }
        
        if input.count <= 3{  return (input, defaultColor) }
        
        // 分离第一个字符和剩余部分
        let textPart = String(input.prefix(1))
        let colorPart = String(input.dropFirst())
        
        // 创建UIColor
        guard let color = UIColor(hexString: colorPart) else {
            return (textPart, defaultColor)
        }
        
        return (textPart, color)
    }
}

extension Character {
    var isEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji } &&
        (unicodeScalars.first?.properties.isEmojiPresentation == true || unicodeScalars.count > 1)
    }
}

