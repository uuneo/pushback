//
//  Extension+.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import Foundation
import SwiftUI
import Combine
import CryptoKit


extension String: @retroactive Error {}


// MARK: -   PreferenceKey+.swift

struct CirclePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


// MARK: - Error+.swift

public struct StringError: Error{
    var info:String
    init(_ info: String) { self.info = info }
}



public enum ApiError: Error {
    case Error(info: String)
    case AccountBanned(info: String)
}

extension Error {
    func rawString() -> String {
        if let err = self as? String {
            return err
        }
        guard let err = self as? ApiError else {
            return self.localizedDescription
        }
        switch err {
        case .Error(let info):
            return info
        case .AccountBanned(let info):
            return info
        }
    }
}


// MARK: -  String+.swift


extension String{
    
    enum urlType{
        case remote, local, none
    }
    
    /// 移除 URL 的 HTTP/HTTPS 前缀
    func removeHTTPPrefix() -> String {
        return self.replacingOccurrences(of: "^(https?:\\/\\/)?", with: "", options: .regularExpression)
    }
    
    func isHttpAndHttps() -> Bool{ ["http", "https"].contains{ self.lowercased().hasPrefix($0) } }
    
    func isURL() -> Bool{
        guard let url = URL(string: self), url.scheme?.isHttpAndHttps() == true, url.host != nil else {
               return false
           }
           return true
    }
    
    /// 判断字符串是否为有效的 URL，并返回图片类型
    func isValidURL() -> urlType {
        guard let url = URL(string: self) else { return .none }
        
        if self.isHttpAndHttps() {
            return .remote
        } else if url.isFileURL {
            return .local
        } else {
            return .none
        }
    }
    
    /// 判断字符串是否为有效的电子邮件地址
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    func isInsideServer()-> Bool{ self.contains("uuneo.com") && self.contains("vcvc.xyz") }
    
    
    /// 判断字符串是否为有效的电话号码（简单示例）
    func isValidPhoneNumber() -> Bool {
        let phoneRegex = "^[0-9]{10,}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
    
    /// 将字符串转换为首字母大写
    func capitalizedFirstLetter() -> String {
        guard !self.isEmpty else { return self }
        return prefix(1).capitalized + dropFirst()
    }
    
    /// 去除字符串两端的空白字符
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func sha256() -> String{
        // 计算 SHA-256 哈希值
        // 将哈希值转换为十六进制字符串
        guard let data = self.data(using: .utf8) else {
            return String(self.prefix(10)) 
        }
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}


// MARK: -  Date+.swift

extension Date {
    func formatString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func agoFormatString() -> String {
        let calendar = Calendar(identifier: .gregorian)
        guard let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date()) as DateComponents? else {
            return String(localized: "未知时间")
        }
        
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        // Check if the date is within the current year
        let isCurrentYear = calendar.isDate(self, equalTo: Date(), toGranularity: .year)
        
        if year > 0 || month > 0 || day > 0 || hour > 12 {
            // Display full date if it's more than 12 hours ago
            if isCurrentYear {
                return formatString(format: "MM-dd HH:mm") // Exclude year if within the current year
            } else {
                return formatString(format: "yyyy-MM-dd HH:mm") // Include year if not the current year
            }
        }
        
        if hour > 1 {
            // Display in hours and minutes if it's more than 1 hour ago
            return formatString(format: "HH:mm")
        }
        if hour > 0 {
            // Display in hours and optionally minutes
            if minute > 0 {
                return String(format: String(localized: "%1$d小时%2$d分钟前"), hour, minute)
            }
            return String(format: String(localized: "%1$d小时前"), hour)
        }
        if minute > 1 {
            // Display in minutes if it's more than 1 minute ago
            return String(format: String(localized: "%1$d分钟前"), minute)
        }
        // Display "just now" for time differences of less than 1 minute
        return String(localized: "刚刚")
    }
    
    // 计算日期与当前日期的差异，并根据差异生成颜色
    func colorForDate() -> Color {
        let now = Date()
        let timeDifference = now.timeIntervalSince(self) // 获取过去的时间差（秒为单位）
        
        let threeHours: TimeInterval = 3 * 60 * 60
        let fiveHours: TimeInterval = 5 * 60 * 60
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        let oneWeek: TimeInterval = 7 * twentyFourHours
        
        // 根据过去时间的长短判断颜色
        // 3小时以内，显示绿色
        if timeDifference <= threeHours {
            return Color.green
        }
        // 3小时到5小时之间，显示黄色
        else if timeDifference <= fiveHours {
            return Color.yellow
        }
        // 5小时到24小时之间，显示蓝色
        else if timeDifference <= twentyFourHours {
            return Color.blue
        }
        // 24小时到一周之间，显示灰色
        else if timeDifference <= oneWeek {
            return Color.gray
        }
        // 超过一周，显示深灰色
        return Color(UIColor.darkGray)
    }
    
    
    /// 计算给定天数减去（当前日期 - 自身日期）的天数
    /// - Parameter days: 给定的天数
    /// - Returns: 剩余的天数
    func daysRemaining(afterSubtractingFrom days: Int) -> Int {
        // 计算当前日期和目标日期之间的天数差
        guard let daysBetween = Calendar.current.dateComponents([.day], from: Date(), to: self).day else {
            return -1
        }
        // 返回给定天数减去天数差
        return days - daysBetween
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow: Date { return Date().dayAfter }
    static var lastHour: Date { return Calendar.current.date(byAdding: .hour, value: -1, to: Date())! }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    
    var noon: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    
    func someDayBefore(_ day: Int)-> Date{
        return Calendar.current.date(byAdding: .day, value: -day, to: noon)!
    }
    
    func someHourBefore(_ hour:Int)-> Date{
        return Calendar.current.date(byAdding: .hour, value: -hour, to: Date())!
    }
    
    var s1970: Date{
        return Calendar.current.date(from: DateComponents(year: 1970, month: 1,day: 1))!
    }
    
    func isExpired(days: Int) -> Bool {
        // 计算指定天数后的日期
        
        guard let targetDate = Calendar.current.date(byAdding: .day, value: days, to: self), days >= 0 else {
            return false
        }
        return Date() > targetDate
    }
}


// MARK: -  URLSession+.swift

extension URLSession{
    enum APIError:Error{
        case invalidURL
        case invalidCode(Int)
    }
    
    func data(for request:URLRequest) async throws -> Data{
    
        let (data,response) = try await self.data(for: request)
        guard let response = response as? HTTPURLResponse else{ throw APIError.invalidURL }
        guard 200...299 ~= response.statusCode else {throw APIError.invalidCode(response.statusCode) }
        return data
    }
    
}

// MARK: -  URLComponents+.swift

extension URLComponents{
    func getParams()-> [String:String]{
        var parameters = [String: String]()
        // 遍历查询项目并将它们添加到字典中
        if let queryItems = self.queryItems {
            
            for queryItem in queryItems {
                if let value = queryItem.value {
                    parameters[queryItem.name] = value
                }
            }
        }
        return parameters
    }
    
    func getParams(from params: [String: Any])-> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        return queryItems
    }
    
    
    
}

// MARK: -  keyPath+.swift


func == <T, Value: Equatable>( keyPath: KeyPath<T, Value>, value: Value) -> (T) -> Bool {
    { $0[keyPath: keyPath] == value }
}


// MARK: - Color.swift


extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    
    static let appDarkGray = Color(hex: "#0C0C0C")
    static let appGray = Color(hex: "#0C0C0C").opacity(0.8)
    static let appLightGray = Color(hex: "#0C0C0C").opacity(0.4)
    static let appYellow = Color(hex: "#FFAC0C")
    
    //Booking
    static let appRed = Color(hex: "#F62154")
    static let appBookingBlue = Color(hex: "#1874E0")
    
    //Profile
    static let appProfileBlue = Color(hex: "#374BFE")
    
}




extension Encodable {
    func toEncodableDictionary() -> [String: Any]? {
        // 1. 使用 JSONEncoder 将结构体编码为 JSON 数据
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        // 2. 使用 JSONSerialization 将 JSON 数据转换为字典
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}



struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension Data{
    func sha256() -> String{
        // 计算 SHA-256 哈希值
        // 将哈希值转换为十六进制字符串
        return SHA256.hash(data: self).compactMap { String(format: "%02x", $0) }.joined()
    }
    
    
    func toThumbnail(max:Int = 300)-> UIImage?{
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max
        ]
        
        if let source = CGImageSourceCreateWithData(self as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            
            return  UIImage(cgImage: cgImage)
        }
        return nil
    }
    
}


extension UInt64{
    func fileSize()->String{
        if self >= 1_073_741_824 { // 1GB
            return String(format: "%.2fGB", Double(self) / 1_073_741_824)
        } else if self >= 1_048_576 { // 1MB
            return String(format: "%.2fMB", Double(self) / 1_048_576)
        } else if self >= 1_024 { // 1KB
            return String(format: "%dKB", self / 1_024)
        } else {
            return "\(self)B" // 小于 1KB 直接显示字节
        }
    }
}

extension URL{
    func findNameAndKey() -> (String,String?){
        guard let scheme = self.scheme, let host = self.host() else { return ("", nil)}
        
        let path = self.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.count > 1 {
            return (scheme + "://" + host, path)
        }
        
        return (scheme + "://" + host, nil)
    }
}
