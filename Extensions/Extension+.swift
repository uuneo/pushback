//
//  Extension+.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import Foundation
import SwiftUI
import Combine

// MARK: -  FontAnimation+.swift

struct FontAnimation: Animatable, ViewModifier{
	
	var size:Double
	var weight:Font.Weight
	var design:Font.Design
	var animatableData: Double{
		get { size }
		set { size = newValue }
	}
	
	func body(content: Content) -> some View {
		content
			.font(.system(size: size,weight: weight,design: design))
	}
	
}

extension View {
	func animationFont(size:Double,weight: Font.Weight = .regular,design:Font.Design = .default )-> some View{
		self.modifier(FontAnimation(size: size, weight: weight, design: design))
	}
}


// MARK: -   PreferenceKey+.swift

struct CirclePreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}


struct markDownPreferenceKey: PreferenceKey {
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
	
	enum ImageType{
		case remote, local, none
	}

	func removeHTTPPrefix() -> String {
		var cleanedURL = self
		if cleanedURL.hasPrefix("http://") {
			cleanedURL = cleanedURL.replacingOccurrences(of: "http://", with: "")
		} else if cleanedURL.hasPrefix("https://") {
			cleanedURL = cleanedURL.replacingOccurrences(of: "https://", with: "")
		}
		return cleanedURL
	}
	
	// 判断字符串是否为 URL 并返回类型
	   func isValidURL() -> ImageType {
		   guard let url = URL(string: self) else { return .none }
		   if let scheme = url.scheme, (scheme == "http" || scheme == "https") {
			   return .remote
		   }
		   return url.isFileURL ? .local : .none
	   }
	
	
	func isValidEmail() -> Bool {
		let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
		let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
		return emailTest.evaluate(with: self)
	}

	func isInsideServer()-> Bool{ self.contains("uuneo.com") && self.contains("vcvc.xyz") }


	func copy(){ UIPasteboard.general.string = self }
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
	
	func data(for request:URLRequest, timeout:Double = 30) async throws -> Data{

		self.configuration.httpAdditionalHeaders = [
			"application/json" : "Content-Type",
			"User-Agent" : self.generateCustomUserAgent()
		]
		self.configuration.timeoutIntervalForRequest = timeout

		let (data,response) = try await self.data(for: request)
		guard let response = response as? HTTPURLResponse else{ throw APIError.invalidURL }
		guard 200...299 ~= response.statusCode else {throw APIError.invalidCode(response.statusCode) }
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


// MARK: -  Notification.Name

// Step 1: 定义通知名称
extension Notification.Name {
	static let messagePreview = Notification.Name("messagePreview")
	static let imageUpdate = Notification.Name("imageUpdate")
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




class KeyboardHeightHelper: ObservableObject {
    // 使用 @Published 属性来发布键盘高度的变化
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 监听键盘将要显示的通知
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .map { $0.height }
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
        
        // 监听键盘将要隐藏的通知
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
    }
}
