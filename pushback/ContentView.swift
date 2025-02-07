//
//  ContentView.swift
//  pushback
//
//  Created by He Cho on 2024/10/25.
//

import SwiftUI
import RealmSwift
import Defaults
import UniformTypeIdentifiers

struct ContentView: View {
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.scenePhase) private var scenePhase
	@EnvironmentObject private var manager:PushbackManager
	@StateObject private var monitor = MonitorsManager()
	@ObservedResults(Message.self) var messages

	@Default(.servers) private var servers
	@Default(.firstStart) private var firstStart
	@Default(.badgeMode) private var badgeMode
	@State private var noShow:NavigationSplitViewVisibility = .detailOnly
	@State private  var showAlart:Bool = false
	@State private  var activeName:String = ""
	@State private var messagesPath: [String] = []

	
	var tabColor2:Color{
		colorScheme == .dark ? Color.white : Color.black
	}
	
	var body: some View {
		
		ZStack{
			
			if ISPAD{
				IpadHomeView()
					
			}else{
				IphoneHomeView()
					
			}
			
			
			if firstStart{
				LauchFirstStartView(){
					withAnimation {
						self.firstStart.toggle()
					}
					
					if let realm = try? Realm(){
						for msg in Message.messages{
							try? realm.write {
								realm.add(msg)
							}
						}
					}
					
					
					PushServerCloudKit.shared.fetchPushServerModels { response in
						switch response {
						case .success(let results):
							withAnimation(.easeInOut) {
								if let result = results.first{
									self.servers.append(result)
									return
								}
							}
						case .failure(let failure):
							debugPrint(failure)
							Toast.shared.present(title: String(localized: "没有找到历史服务器"), symbol: .error)
							self.servers.append(PushServerModel(url: BaseConfig.defaultServer))
						}
						
						
					}
					
					
				}
				.background(.white.gradient)
			}
			
		}
		.sheet(isPresented: manager.sheetShow){ ContentSheetViewPage() }
		.fullScreenCover(isPresented: manager.fullShow){ ContentFullViewPage() }
		.onChange(of: scenePhase, perform: self.backgroundModeHandler)
		.onOpenURL(perform: self.openUrlView)
		.alert(isPresented: $showAlart) {
			Alert(title:
					Text( "操作不可逆!"),
				  message:
					Text( activeName == "alldelnotread" ? "是否确认删除所有未读消息!" :  "是否确认删除所有已读消息!"
						),
				  primaryButton:
					.destructive(
						Text("删除"),
						action: {
							RealmManager.shared.read(activeName == "alldelnotread")
						}
					), secondaryButton: .cancel())
		}
		.task {
			for await value in Defaults.updates(.servers) {
				try? await Task.sleep(for: .seconds(1))
				await manager.registers()
				PushServerCloudKit.shared.updatePushServers(items: value)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .messagePreview)) { _ in
			// 接收到通知时的处理
			manager.page = .message
		}
		
		
	}
	
	
	@ViewBuilder
	func IphoneHomeView()-> some View{
		TabView(selection: Binding(get: {
			manager.page
		}, set: { value in
			manager.page = value
		})) {
			
			// MARK: 信息页面
			MessageHomeView()
				.badge(messages.where({!$0.read}).count)
				.tabItem {
					Label( "消息", systemImage: "ellipsis.message")
						.symbolRenderingMode(.palette)
						.foregroundStyle( .green, tabColor2)
				}
				.tag(TabPage.message)
				
			
			// MARK: 设置页面
			
			SettingsView()
				.tabItem {
					Label( "设置", systemImage: "gear.badge.questionmark")
						.symbolRenderingMode(.palette)
						.foregroundStyle( .green, tabColor2)
					
				}
				.tag(TabPage.setting)
				
			
		}

	}
	
	@ViewBuilder
	func IpadHomeView() -> some View{
		NavigationSplitView(columnVisibility: $noShow) {
			SettingsView()
		} detail: {
			MessageHomeView()
		}
		
	}
	
	
	@ViewBuilder
	func ContentFullViewPage() -> some View{
		
		switch manager.fullPage {
		case .customKey:
			ChangeKeyView()
		case .servers:
			ServersConfigView(showClose: true)
		case .music:
			SoundView()
		case .scan:
			ScanView { code in
				manager.appendServer(server: PushServerModel(url: code)) { server, msg in
					Toast.shared.present(title: msg, symbol: "document.viewfinder")
				}
				
			}
		case .web(let url):
			SFSafariView(url: url)
				.ignoresSafeArea()
		default:
			EmptyView()
				.onAppear{
					DispatchQueue.main.asyncAfter(deadline: .now() + 1){
						manager.fullPage = .none
					}
				}
		}
	}
	
	@ViewBuilder
	func ContentSheetViewPage() -> some View {
		switch manager.sheetPage {
		case .servers:
			ServersConfigView(showClose: true)
		case .appIcon:
			NavigationStack{
				AppIconView()
			}.presentationDetents([.height(300)])
				
		case .web(let url):
			SFSafariView(url: url)
				.ignoresSafeArea()
		default:
			EmptyView()
				.onAppear{
					manager.sheetPage = .none
				}
		}
	}
}

extension ContentView{
	
	func openUrlView(url: URL){
		guard let scheme = url.scheme,
			  let host = url.host(),
			  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else{ return }
		
		let params = components.getParams()
#if DEBUG
		debugPrint(scheme, host, params)
#endif
		
		
		if host == "login"{
			if let url = params["url"]{
				
				manager.scanUrl = url
				manager.fullPage = .customKey

			}else{
				Toast.shared.present(title: String(localized: "参数错误"), symbol: "questionmark.circle.dashed")
			}
			
		}else if host == "add"{
			if let url = params["url"]{
				
				servers.append(PushServerModel(url: url))

				if !manager.showServerListView {
					manager.fullPage = .none
					manager.sheetPage = .none
					manager.page = .setting
					manager.showServerListView = true
				}
			}else{
				Toast.shared.present(title: String(localized: "参数错误"), symbol: "questionmark.circle.dashed")
			}
		}
	}
	
	func backgroundModeHandler(newValue: ScenePhase){
		switch newValue{
		case .active:
			BaseConfig.stopCallNotificationHandler()
			if let name = QuickAction.selectAction?.userInfo?["name"] as? String{
				QuickAction.selectAction = nil
				manager.page = .message
				switch name{
				case "allread":
					RealmManager.shared.read()
					Toast.shared.present(title: String(localized: "操作成功"), symbol: "questionmark.circle.dashed")
				case "alldelread","alldelnotread":
					self.activeName = name
					self.showAlart.toggle()
				default:
					break
				}
			}
			
			HapticsManager.shared.restartEngine()
			Task.detached {
				await manager.registers()
			}
			
		case .background:
			UIApplication.shared.shortcutItems = QuickAction.allShortcutItems
			HapticsManager.shared.stopEngine()
			
			
		default:
			break
		}
		
		RealmManager.shared.deleteExpired()
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
		RealmManager.ChangeBadge()
	}

}

#Preview {
	ContentView()
		.environmentObject(PushbackManager.shared)
}
