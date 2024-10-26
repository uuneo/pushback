//
//  PushBackManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

import SwiftUI
import Defaults


class PushBackManager: ObservableObject{
	static let shared = PushBackManager()
	
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
	// MARK: - Remote Request
	
	/// Request Data
	func fetch<T:Codable>(url:String) async throws -> T?{
		guard let requestUrl = URL(string: url) else {return  nil}
		let data = try await session.data(for: URLRequest(url: requestUrl))
		let result = try JSONDecoder().decode(T.self, from: data)
		return result
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
				let url = server.url + "/register/" + deviceToken + "/" + server.key
				
				let response:baseResponse<DeviceInfo>? = try await self.fetch(url: url)
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
			let (_, success, msg) = await self.health(url: server.url)
			if success {
				await MainActor.run {
					Defaults[.servers].insert(server, at: 0)
				}
				let (serverresult,msg) = await self.register(server: server)
				completion(serverresult,msg)
			}else{
				completion(server ,msg ?? "")
			}
		}
	}
	
	// MARK: - Tools Function
	
	/// Copy information to clipboard
	func copy(_ text:String){
		UIPasteboard.general.string = text
	}
	
	/// Add Hold app to display the shortcut menu
	func addQuickActions(){
		UIApplication.shared.shortcutItems = QuickAction.allShortcutItems
	}
	
	/// open app settings
	func openSetting(){
		guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
			return
		}
		
		UIApplication.shared.open(settingsURL)
	}
	
	
	///  open url or urlscheme
	func openUrl(url: URL, unOpen: ((URL)->Void)?) {
		if url.path().isValidURL() != .remote{
			UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: true]) { success in
				if !success {
					unOpen?(url)
				}
			}
		}
		else {
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
			let soundsDirectoryUrl = getSoundsDirectory()
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
	
	
	/// 将指定文件保存在 Library/Sound，如果存在则覆盖
	func saveSound(url: URL) {
		let soundsDirectoryUrl = getSoundsDirectory()
		saveFile(to: soundsDirectoryUrl, from: url)
		saveSoundToGroupDirectory(url: url)
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
	
	/// 获取 Library 目录下的 Sounds 文件夹
	/// 如果不存在就创建
	private func getSoundsDirectory() -> URL {
		let soundFolderPath = manager.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent(BaseConfig.Sounds)
		
		var isDirectory: ObjCBool = false
		
		if !manager.fileExists(atPath: soundFolderPath.path, isDirectory: &isDirectory) || !isDirectory.boolValue{
			try? manager.createDirectory(at: soundFolderPath, withIntermediateDirectories: true, attributes: nil)
		}
		
		return soundFolderPath
	}
	
	/// 保存到共享文件夹，供 NotificationServiceExtension 使用
	private func saveSoundToGroupDirectory(url: URL) {
		if let groupDirectoryUrl = getSoundsGroupDirectory() {
			saveFile(to: groupDirectoryUrl, from: url)
		}
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
	
	
	
	/// 通用文件保存方法
	private func saveFile(to directoryUrl: URL, from sourceUrl: URL) {
		let destinationUrl = directoryUrl.appendingPathComponent(sourceUrl.lastPathComponent)
		if manager.fileExists(atPath: destinationUrl.path) {
			try? manager.removeItem(at: destinationUrl)
		}
		try? manager.copyItem(at: sourceUrl, to: destinationUrl)
	}
	
	
}



