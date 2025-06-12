//
//  PushbackManager.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import UIKit
import SwiftUI
import Defaults
import Foundation


class AppManager:  NetworkManager, ObservableObject, @unchecked Sendable {
	static let shared = AppManager()
	
    @Published var page:TabPage = .message
	@Published var sheetPage:SubPage = .none
	@Published var fullPage:SubPage = .none
	@Published var scanUrl:String = ""
    @Published var crashLog:String?
    
	@Published var PremiumUser:Bool = false
    
    
    @Published var selectId:String? = nil
    @Published var selectGroup:String? = nil
    @Published var searchText:String = ""
    
    
    @Published var router:[RouterPage] = []
    
    @Published var isWarmStart:Bool = false
    
    @Published var selectMessage:Message? = nil
    @Published var selectPoint:CGPoint = .zero
    /// 首页彩色框
    @Published var isLoading:Bool = false
    @Published var inAssistant:Bool = false
    
    /// 问智能助手
    @Published var askMessageId:String? = nil
    /// 开始播放语音
    @Published var speaking:Bool = false
    
    
   
    
    var fullShow:Binding<Bool>{
        Binding {
            self.fullPage != .none
        } set: { _ in
            self.fullPage = .none
        }
    }
    
    var sheetShow:Binding<Bool>{
        Binding {
            self.sheetPage != .none
        } set: { _ in
            self.sheetPage = .none
        }
    }
    


	
	private override init() { super.init() }
    
    
    func restore(address:String, deviceKey:String) async -> Bool{
        let response:baseResponse<String>? = try? await self.fetch(url: address + "/register/\(deviceKey)")
        if let msg = response?.message, let code = response?.code,code == 200, msg == "success"{
            let success = await self.appendServer(server: PushServerModel(url: address,key: deviceKey))
            return success
        }else{
            return false
        }
    }
    
    func registers(msg:Bool = false){
        Task.detached(priority: .userInitiated) {
            let servers = Defaults[.servers]
            let results =  await withTaskGroup(of: PushServerModel.self){ group in
                
                for server in servers {
                    group.addTask{  await self.register(server: server,msg: msg) }
                }
                var results:[PushServerModel] = []
                
                for await result in group{
                    results.append(result)
                }
                return results
            }
            await MainActor.run {
                Defaults[.servers] = results
                Self.syncLocalToCloud()
            }
        }
    }

    
    func register(server:PushServerModel, reset:Bool = false, msg:Bool = true) async -> PushServerModel{
        var server = server
        
        do{ 
            
            let deviceToken = reset ? UUID().uuidString : Defaults[.deviceToken]
            let params  = DeviceInfo(deviceKey: server.key, deviceToken: deviceToken ).toEncodableDictionary() ?? [:]
            
            let response:baseResponse<DeviceInfo> = try await self.fetch(url: server.url + "/register",method: .post, params: params)
            
            if let data = response.data {
                server.key = data.deviceKey
                server.status = true
                if msg{
                    if reset{
                        Toast.info(title: "解绑成功")
                    }else{
                        Toast.success(title: "注册成功")
                    }
                    
                }
            }else{
                server.status = false
                if msg{
                    Toast.error(title: "注册失败")
                }
            }
            
            return server
        }catch{
            debugPrint(error.localizedDescription)
            return server
        }
    }
    

    func appendServer(server:PushServerModel) async -> Bool{
        
        if Defaults[.deviceToken].count < 5{
            AppManager.shared.registerForRemoteNotifications()
        }
        
        guard !Defaults[.servers].contains(where: {$0.key == server.key && $0.url == server.url})else{
            Toast.error(title: "服务器已存在")
            return false
        }
        let server = await self.register(server: server)
        if server.status {
            await MainActor.run {
                Defaults[.servers].insert(server, at: 0)
                Self.syncLocalToCloud()
            }
            Toast.success(title: "添加成功")
        }
        return server.status
    }
    
    class func syncLocalToCloud() {
        let locals = Defaults[.servers]
        var clouds = Defaults[.cloudServers]

        let cloudServerSet = Set(clouds.map { $0.server })

        let newItems = locals.filter { !cloudServerSet.contains($0.server) }

        if !newItems.isEmpty {
            clouds.append(contentsOf: newItems)
            Defaults[.cloudServers] = clouds
        }
    }

     func HandlerOpenUrl(url:URL){
       
        switch self.outParamsHandler(address: url.absoluteString) {
        case .crypto(let text):
            Log.debug(text)
            DispatchQueue.main.async{
                self.page = .setting
                self.router = [.more, .crypto(text)]
            }
        case .server(let url):
            Task.detached(priority: .userInitiated) {
                let success = await self.appendServer(server: PushServerModel(url: url))
                if success{
                    DispatchQueue.main.async {
                        self.page = .setting
                        self.router = [.server]
                    }
                }
            }
        case .serverKey(let url, let key):
            Task.detached(priority: .userInitiated) {
                let success = await self.restore(address: url, deviceKey: key)
                if success{
                    DispatchQueue.main.async {
                        self.page = .setting
                        self.router = [.server]
                    }
                }
            }
        case .assistant(let text):
            if let account = AssistantAccount(base64: text){
                DispatchQueue.main.async {
                    self.router.append(.assistantSetting(account))
                }
            }
        case .page(page: let page,title: let title, data: let data):
            switch page{
            case .widget:
                DispatchQueue.main.async {
                    self.page = .setting
                    self.router = [.more, .widget(title: title, data: data)]
                }
            case .icon:
                self.page = .setting
                self.sheetPage = .cloudIcon
            }
        default:
            break
            
        }
    }
    
}


extension AppManager{
    /// open app settings
    static func openSetting(){
        AppManager.openUrl(url: URL(string: UIApplication.openSettingsURLString)!)
    }
    /// Open a URL or handle a fallback if the URL cannot be opened
    /// - Parameters:
    ///   - url: The URL to open
    ///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
    class func openUrl(url: URL, unOpen: ((URL) -> Void)? = nil) {

        if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {

            switch Defaults[.defaultBrowser] {
                case .app:
                    AppManager.shared.fullPage = .web(url.absoluteString)
                case .safari:
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }


    
    class func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to: nil,from: nil,for: nil)
    }
    
    
    // MARK: 注册设备以接收远程推送通知
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert, .providesAppNotificationSettings]) { (granted, error) in

            if granted {
                // 如果授权，注册设备接收推送通知
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                Toast.error(title: "没有打开推送")
            }
        }
    }
    
    func clearContentsOfDirectory(at url: URL) {
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])

            for fileURL in contents {
                do{
                    try fileManager.removeItem(at: fileURL)
                    print("✅ 删除: \(fileURL.lastPathComponent)")
                }catch{
                    print("❌ 清空失败: \(error.localizedDescription)")
                }
            }
            
            print("🧹 清空完成：\(url.path)")
        } catch {
            print("❌ 清空失败: \(error.localizedDescription)")
        }
    }
    
    func calculateDirectorySize(at url: URL) -> UInt64 {
        var totalSize: UInt64 = 0

        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    if resourceValues.isRegularFile == true {
                        if let fileSize = resourceValues.fileSize {
                            totalSize += UInt64(fileSize)
                        }
                    }
                } catch {
                    print("❗️获取文件大小失败: \(fileURL.lastPathComponent) - \(error.localizedDescription)")
                }
            }
        }

        return totalSize
    }
    
    
    func outParamsHandler(address:String) -> OutDataType{
        
        guard let url = URL(string: address), let scheme = url.scheme?.lowercased() else {
            return .text(address)
        }
        
        
        if PBScheme.schemes.contains(scheme),let host = url.host(),let host = PBScheme.HostType(rawValue: host), let components = URLComponents(url: url, resolvingAgainstBaseURL: false){
            let params = components.getParams()
            
            if host == .server, let url = params["text"],let urlResponse = URL(string: url), url.hasHttp() {
                let (result, key) = urlResponse.findNameAndKey()
                if let key{
                    return .serverKey(url: result, key: key)
                }else {
                    return .server(result)
                }
            }
    
            if host == .crypto,let config = params["text"]{
                return .crypto(config)
            }
            
            if host == .assistant, let config = params["text"]{
                return .assistant(config)
            }
            
            /// pb://openPage?type=widget&page=small
            if host == .openPage, let page = params["page"], let page = OutDataType.pageType(rawValue: page) {
                return .page(page: page,title: params["title"], data: params["data"] ?? "")
            }
        
            
        }
        
        return .otherUrl(address)
    }
    
    
    
}

