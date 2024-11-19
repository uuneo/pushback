//
//  PushbackManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

import SwiftUI
import Defaults


class PushbackManager: ObservableObject{
	static let shared = PushbackManager()
	
	private let session = URLSession(configuration: .default)
	
	@Published var page:TabPage = .message
	@Published var sheetPage:SubPage = .none
	@Published var fullPage:SubPage = .none
	@Published var webUrl:String = ""
	@Published var scanUrl:String = ""
	@Published var showServerListView:Bool = false
	
	@Published var defaultSounds:[URL] =  []
	@Published var customSounds:[URL] =  []
	
	private let appGroupIdentifier = BaseConfig.groupName
	
	private var customSoundsDirectoryMonitor: DispatchSourceFileSystemObject?
	private let manager = FileManager.default
	
	var fullShow:Binding<Bool>{
		
		Binding {
			self.fullPage != .none
		} set: { value in
			if !value {
				self.fullPage = .none
			}
		}
	}
	
	var sheetShow:Binding<Bool>{
		Binding {
			self.sheetPage != .none
		} set: { value in
			if !value {
				self.sheetPage = .none
			}
		}
		
	}
	
	
	private init() {
		/// get sound file list
		getFileList()
	}
	
	
}

extension PushbackManager{
	// MARK: - Remote Request
	
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
		
		// 如果是 POST 请求且有参数，将参数编码为 JSON 并设置为请求体
		if method == .post, let params = params {
			request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
		}
		
		// 发送请求并解析响应
		let (data, _) = try await URLSession.shared.data(for: request)
		let result = try JSONDecoder().decode(T.self, from: data)
		return result
	}
	
	func changeKey(server:PushServerModal, newKey:String) async -> Bool{
		
		do{
			
			let params = ChangeKeyInfo(oldKey: server.key, newKey: newKey, deviceToken: Defaults[.deviceToken]).toEncodableDictionary()
			
			if let response:baseResponse<ChangeKeyInfo> = try await self.fetch(url: "\(server.url)/change",method: .post, params: params),
			   let index = Defaults[.servers].firstIndex(where: {$0.id == server.id}){
				if let data = response.data{
					Defaults[.servers].remove(at: index)
					Defaults[.servers].append(PushServerModal(url: server.url,key: data.newKey))
					Toast.shared.present(title: String(localized: "修改成功"), symbol: .success)
					return true
				}else{
					Toast.shared.present(title: response.message, symbol: .error)
					return false
				}
				
			}
			   
			
		}catch{
			debugPrint(error.localizedDescription)
			Toast.shared.present(title: error.localizedDescription, symbol: .error)
			return false
		}
		
		Toast.shared.present(title: String(localized: "修改失败"), symbol: .error)
		
		return false
	}
	
	/// Update Server Status
	///  - Parameters:
	///  	- completion: (  url, success, message ) - > void
	func health(url: String) async -> (String, Bool, String?) {
		let healthUrl = url + "/health"
		do{
			let response:String? = try await self.fetch(url: healthUrl)
			let success = response == "ok"
			await MainActor.run {
				if 	let index = Defaults[.servers].firstIndex(where: {$0.url  == url}){
					Defaults[.servers][index].status = success
				}
			}
			return (url,success, "")
		}catch{
			await MainActor.run {
				if 	let index = Defaults[.servers].firstIndex(where: {$0.url  == url}){
					Defaults[.servers][index].status = false
				}
			}
			
			return (url,false, error.localizedDescription)
		}
	}
	/// Update All Server Status
	///  - Parameters:
	///  	- completion: [(  url: 网址, bool: 是否成功, string: 提示消息 )]- > void
	func healths(completion: (([(String, Bool, String?)])-> Void)? = nil){
		Task.detached(priority: .background) {
			await withTaskGroup(of:(String, Bool, String?).self){ group in
				for server in Defaults[.servers] {
					group.addTask{  await self.health(url: server.url)  }
				}
				
				var results:[(String, Bool, String?)] = []
				
				for await result in group{
					results.append(result)
				}
				completion?(results)
			}
			
		}
	}
	
	/// Register  Server
	///  - Parameters:
	///  server: 服务器数据
	///  completion: 服务器数据，提示消息
	func register(server: PushServerModal, completion: ((PushServerModal,String)-> Void)? = nil){
		Task.detached(priority: .high) {
			let (server1,msg) = await self.register(server: server)
			completion?(server1, msg)
		}
	}
	
	/// Register  Servers Status
	///  - Parameters:
	///  server: 服务器数据
	///  completion: 列表 ( 服务器数据，提示消息 )
	func registers(completion: (([(PushServerModal,String)])-> Void)? = nil){
		Task.detached(priority: .background) {
			
			await withTaskGroup(of: (PushServerModal,String).self) { group in
				for server in Defaults[.servers] {
					group.addTask {await self.register(server: server)}
				}
				
				var results:[(PushServerModal,String)] = []
				for await result in group{
					results.append(result)
				}
				completion?(results)
			}
		}
	}
	
	
	/// Register  Server async
	func register(server: PushServerModal) async -> (PushServerModal,String){
		
		do{
			let deviceToken = Defaults[.deviceToken]
			if let index = Defaults[.servers].firstIndex(of: server){
			
				let params  = DeviceInfo(deviceKey: server.key, deviceToken: deviceToken ).toEncodableDictionary()
				
				
				let response:baseResponse<DeviceInfo>? = try await self.fetch(url: server.url + "/register",method: .post, params: params)
				
				if let response = response,
				   let data = response.data
				{
					
					
					DispatchQueue.main.async{
						Defaults[.servers][index].key = data.deviceKey
						Defaults[.servers][index].status = true
					}
					return (server,"注册成功")
				}else{
					DispatchQueue.main.async{
						Defaults[.servers][index].status = false
					}
				}
				
				
			}
			
		}catch{
			if let index = Defaults[.servers].firstIndex(of: server){
				Defaults[.servers][index].status = false
			}
			print(error.localizedDescription)
			return (server,error.localizedDescription)
		}
		
		return (server,"注册失败")
	}
	
	
	
	/// add server
	func appendServer(server:PushServerModal, completion: @escaping (PushServerModal,String)-> Void ){
		Task.detached(priority: .background) {
			let isServer = Defaults[.servers].contains(where: {$0.url == server.url})
			let (_, success, msg) = await self.health(url: server.url)
			if !isServer, success {
				await MainActor.run {
					Defaults[.servers].insert(server, at: 0)
				}
				let (serverresult,msg) = await self.register(server: server)
				completion(serverresult,msg)
			}else{
				completion(server , isServer ? String(localized: "服务器已存在") : (msg ?? ""))
			}
		}
	}
	
	
	
}


extension PushbackManager{
	// MARK: - Tools Function
	
	/// Copy information to clipboard
	func copy(_ text:String){
		UIPasteboard.general.string = text
	}
	
	
	/// open app settings
	func openSetting(){
		guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
			return
		}
		
		UIApplication.shared.open(settingsURL)
	}
	/// Open a URL or handle a fallback if the URL cannot be opened
	/// - Parameters:
	///   - url: The URL to open
	///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
	func openUrl(url: URL, unOpen: ((URL) -> Void)? = nil) {
		// Check if the URL can be opened
		if UIApplication.shared.canOpenURL(url) {
			// Attempt to open the URL as a universal link
			UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]) { success in
				if !success {
					// If the universal link cannot be opened, call the fallback closure
					unOpen?(url)
				}
			}
		} else {
			// Fallback to opening the URL normally if it's not a universal link or cannot be opened
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}
	}
	
	// MARK: - Get audio folder data
	
	private func getFileList() {
		let defaultSounds:[URL] = {
			var temurl = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
			temurl.sort { u1, u2 -> Bool in
				u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
			}
			return temurl
		}()
		
		let customSounds: [URL] = {
			guard let soundsDirectoryUrl = getSoundsGroupDirectory() else { return []}
			
			var urlemp = self.getFilesInDirectory(directory: soundsDirectoryUrl.path(), suffix: "caf")
			urlemp.sort { u1, u2 -> Bool in
				u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
			}
			
			return urlemp
		}()
		
		DispatchQueue.main.async {
			self.customSounds = customSounds
			self.defaultSounds = defaultSounds
		}
		
	}
	
	/// 返回指定文件夹，指定后缀的文件列表数组
	func getFilesInDirectory(directory: String, suffix: String) -> [URL] {
		
		do {
			let files = try manager.contentsOfDirectory(atPath: directory)
			return files.compactMap { file -> URL? in
				if file.hasSuffix(suffix) {
					return URL(fileURLWithPath: directory).appendingPathComponent(file)
				}
				return nil
			}
		} catch {
			return []
		}
	}
	
	
	/// 通用文件保存方法
	func saveSound(url sourceUrl: URL, name lastPath: String? = nil) {
		guard let groupDirectoryUrl = getSoundsGroupDirectory() else  {
			return
		}
		
		var destinationUrl:URL{
			if let lastPath {
				return groupDirectoryUrl.appendingPathComponent(lastPath)
			}else{
				return groupDirectoryUrl.appendingPathComponent(sourceUrl.lastPathComponent)
			}
		}
		
		
		if manager.fileExists(atPath: destinationUrl.path) {
			try? manager.removeItem(at: destinationUrl)
		}
		
		do{
			try manager.copyItem(at: sourceUrl, to: destinationUrl)
			Toast.shared.present(title: String(localized: "保存成功"), symbol: .success)
		}catch{
			Toast.shared.present(title: error.localizedDescription, symbol: .error)
		}
		
		
		
		
		
		getFileList()
	}
	
	func deleteSound(url: URL) {
		// 删除sounds目录铃声文件
		try? manager.removeItem(at: url)
		// 删除共享目录中的文件
		if let groupSoundUrl = getSoundsGroupDirectory()?.appendingPathComponent(url.lastPathComponent) {
			try? manager.removeItem(at: groupSoundUrl)
		}
		getFileList()
	}
	
	
	/// 获取共享目录下的 Sounds 文件夹，如果不存在就创建
	private func getSoundsGroupDirectory() -> URL? {
		if let directoryUrl = manager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?.appendingPathComponent(BaseConfig.Sounds) {
			if !manager.fileExists(atPath: directoryUrl.path) {
				try? manager.createDirectory(at: directoryUrl, withIntermediateDirectories: true, attributes: nil)
			}
			return directoryUrl
		}
		return nil
	}
	
	
	
	func hideKeyboard() {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
	
}


