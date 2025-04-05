//
//  PushbackManager.swift
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import SwiftUI
import Defaults
import UIKit
import Foundation

class PushbackManager: NetworkManager, ObservableObject{
	static let shared = PushbackManager()
	
	private let session = URLSession(configuration: .default)
	
	@Published var page:TabPage = .message
	@Published var sheetPage:SubPage = .none
	@Published var fullPage:SubPage = .none
	@Published var scanUrl:String = ""
	@Published var crashLog:String?
	@Published var disabled:Bool = false
    
    
    @Published var selectId:String? = nil
    @Published var selectGroup:String? = nil
    
    
    @Published var messagePath:[MessageStatckPage] = []
    
    @Published var isWarmStart:Bool = false
    
    private static var lastFeedbackTime: TimeInterval = 0
    private static let cooldown: TimeInterval = 0.1
	
    var fullShow:Binding<Bool>{  Binding { self.fullPage != .none } set: { _ in self.fullPage = .none } }
	
	var sheetShow:Binding<Bool>{ Binding { self.sheetPage != .none } set: { _ in self.sheetPage = .none } }


	
	private override init() { super.init() }


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
                    withAnimation{
                        Defaults[.servers][index].status = success
                    }
				}
			}
			return (url,success, "")
		}catch{
			await MainActor.run {
				if 	let index = Defaults[.servers].firstIndex(where: {$0.url  == url}){
                    withAnimation{
                        Defaults[.servers][index].status = false
                    }
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
    
    
    func restore(address:String, deviceKey:String, complete:((Bool)->Void)? = nil) {
        Task{
            do{
            
                let response:baseResponse<String>? = try await self.fetch(url: address + "/register/\(deviceKey)",method: .get)
                if let msg = response?.message, let code = response?.code,code == 200, msg == "success"{
                    
                    self.appendServer(server: PushServerModel(url: address,key: deviceKey)) { success, msg in
                        complete?(success)
                    }
                }
                
            }catch{
                Log.error(error.localizedDescription)
              
            }
            complete?(false)
        }
        
    }

	/// Register  Server
	///  - Parameters:
	///  server: 服务器数据
	///  completion: 服务器数据，提示消息
    func register(server: PushServerModel, reset:Bool = false, completion: ((Bool,String)-> Void)? = nil){
		Task.detached(priority: .high) {
            let (success,msg) = await self.register(server: server,reset: reset)
			completion?(success, msg)
		}
	}

	/// Register  Servers Status
	///  - Parameters:
	///  server: 服务器数据
	///  completion: 列表 ( 服务器数据，提示消息 )
    func registers(completion: (([(Bool,String)])-> Void)? = nil) async {
        await withTaskGroup(of: (Bool,String).self) { group in
			for server in Defaults[.servers] {
				group.addTask {await self.register(server: server)}
			}

            var results:[(Bool,String)] = []
			for await result in group{
				results.append(result)
			}
			completion?(results)
		}
	}
    
	/// Register  Server async
    func register(server: PushServerModel, reset:Bool = false) async -> (Bool,String){

		do{
            let deviceToken = reset ? UUID().uuidString : Defaults[.deviceToken]
            
			if let index = Defaults[.servers].firstIndex(of: server){

				let params  = DeviceInfo(deviceKey: server.key, deviceToken: deviceToken ).toEncodableDictionary() ?? [:]

				let response:baseResponse<DeviceInfo>? = try await self.fetch(url: server.url + "/register",method: .post, params: params)

				if let response = response,  let data = response.data {
                    if !reset{
                        DispatchQueue.main.async{
                            Defaults[.servers][index].key = data.deviceKey
                            withAnimation{
                                Defaults[.servers][index].status = true
                            }
                        }
                    }
                    return (true,String(localized: "注册成功"))
				}else{
                    if !reset{
                        DispatchQueue.main.async{
                            withAnimation{
                                Defaults[.servers][index].status = false
                            }
                        }
                    }
				}
			}

		}catch{
			if let index = Defaults[.servers].firstIndex(of: server){
                withAnimation{
                    Defaults[.servers][index].status = false
                }
			}
            Log.error(error.localizedDescription)
			return (false,error.localizedDescription)
		}

		return (true,String(localized: "注册失败"))
	}



	/// add server
   func appendServer(server:PushServerModel, completion: @escaping (Bool,String)-> Void ){
		Task.detached(priority: .background) {
            let isServer = Defaults[.servers].contains(where: {$0.key == server.key})
			let (_, success, msg) = await self.health(url: server.url)
			if !isServer, success {
				await MainActor.run {
					Defaults[.servers].insert(server, at: 0)
				}
				let (success,msg) = await self.register(server: server)
				DispatchQueue.main.async{
					completion(success, msg)
				}
			}else{
				DispatchQueue.main.async{
                    
                    let msg = isServer ? String(localized: "服务器已存在") : (msg ?? "")
                   
					completion(false , msg)
                    
                    
                    
				}
			}
		}
	}

	/// open app settings
	static func openSetting(){
        PushbackManager.openUrl(url: URL(string: UIApplication.openSettingsURLString)!)
	}
	/// Open a URL or handle a fallback if the URL cannot be opened
	/// - Parameters:
	///   - url: The URL to open
	///   - unOpen: A closure called when the URL cannot be opened, passing the URL as an argument
	class func openUrl(url: URL, unOpen: ((URL) -> Void)? = nil) {

		if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {

			switch Defaults[.defaultBrowser] {
				case .app:
					PushbackManager.shared.fullPage = .web(url.absoluteString)
				case .safari:
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}

		} else {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}
	}

    
    class func vibration(style: UIImpactFeedbackGenerator.FeedbackStyle, custom:Bool = false) {
        if !custom {
            let now = Date().timeIntervalSince1970
            guard now - lastFeedbackTime > cooldown else { return } // 限制频率
            lastFeedbackTime = now
        }
       
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    
    class func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to: nil,from: nil,for: nil)
    }
    
}



