//
//  ContentView.swift
//  pushback
//
//  Created by lynn on 2025/4/3.
//


import SwiftUI
import RealmSwift
import Defaults
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var manager = PushbackManager.shared
    @StateObject private var appstate = AppState.shared
    @StateObject private var chatManager = openChatManager.shared
    @ObservedResults(Message.self) var messages
    
    @Default(.servers) private var servers
    @Default(.firstStart) private var firstStart
    @Default(.badgeMode) private var badgeMode
    @Default(.lang) private var lang
    @State private var noShow:NavigationSplitViewVisibility = .detailOnly
    @State private  var showAlart:Bool = false
    @State private  var activeName:String = ""
    @State private var messagesPath: [String] = []
    
    var tabColor2:Color{
        colorScheme == .dark ? Color.white : Color.black
    }
    
    
    var body: some View {
        
        ZStack{
            
            IphoneHomeView()
                .if(ISPAD) { _ in
                    IpadHomeView()
                }
            
            if firstStart{
                firstStartLauchFirstStartView()
            }
        }
        .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
        .overlay{
            if let message = manager.selectMessage{
                SelectMessageView(message: message) {
                    withAnimation(.easeInOut){
                        manager.selectMessage = nil
                    }
                }
            }
        }
        .overlay{
            if chatManager.isLoading && chatManager.inAssistant{
                ColoredBorder()
            }
        }
        .sheet(isPresented: manager.sheetShow){ ContentSheetViewPage().customPresentationCornerRadius(20) }
        .fullScreenCover(isPresented: manager.fullShow){ ContentFullViewPage() }
        .onChange(of: scenePhase, perform: self.backgroundModeHandler)
        .onOpenURL(perform: self.openUrlView)
        .alert(isPresented: $showAlart) { Alert(title:
                    Text( "操作不可逆!"),
                  message:
                    Text( activeName == "alldelnotread" ? "是否确认删除所有未读消息!" :  "是否确认删除所有已读消息!"),
                  primaryButton:
                    .destructive(
                        Text("删除"),
                        action: {
                            
                            if activeName == "alldelnotread"{
                                RealmManager.handler { proxy in
                                    let datas = proxy.objects(Message.self).where({!$0.read})
                                    proxy.writeAsync {
                                        datas.setValue(true, forKey: "read")
                                    }
                                }
                            }
                            
                            
                        }
                    ), secondaryButton: .cancel()) }
        .task {  for await value in Defaults.updates(.servers) {
                try? await Task.sleep(for: .seconds(1))
                await manager.registers()
                PushServerCloudKit.shared.updatePushServers(items: value)
            } }
    }
    
    @ViewBuilder
    func IphoneHomeView()-> some View{
        TabView(selection: Binding(get: {
            manager.page
        }, set: { value in
            manager.page = value
        })) {
            
            
            NavigationStack(path: $manager.router){
                // MARK: 信息页面
                MessagePage()
                    .router(manager: manager, chatManager: chatManager, appstate: appstate)
                
            }
            .badge(messages.where({!$0.read}).count)
            .tabItem {
                Label( "消息", systemImage: "ellipsis.message")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .green, tabColor2)
            }
            .tag(TabPage.message)
            
            
            
            NavigationStack(path: $manager.router){
                // MARK: 设置页面
                SettingsPage()
                    .router(manager: manager, chatManager: chatManager, appstate: appstate)
                
            }
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
            SettingsPage()
                .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
        } detail: {
            
            NavigationStack(path: $manager.router){
                MessagePage()
                    .router(manager: manager, chatManager: chatManager, appstate: appstate)
            }
        }
        
        
    }
    
    @ViewBuilder
    func ContentFullViewPage() -> some View{
        Group{
            switch manager.fullPage {
            case .customKey:
                ChangeKeyView()
            case .scan:
                ScanView{ code in
                    if code.isValidURL() == .remote{
                        manager.appendServer(server: PushServerModel(url: code)) { success, msg in
                            if success{
                                manager.router = [.server]
                            }
                            Toast.shared.present(title: msg, symbol: "document.viewfinder")
                        }
                        return true
                    }
                    return false
                    
                }
            case .web(let url):
                SFSafariView(url: url)
                    .ignoresSafeArea()
            default:
                EmptyView()
                    .onAppear{
                        manager.fullPage = .none
                    }
            }
        }
        .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
        
    }
    
    @ViewBuilder
    func ContentSheetViewPage() -> some View {
        Group{
            switch manager.sheetPage {
            case .appIcon:
                NavigationStack{
                    AppIconView()
                }.presentationDetents([.height(300)])
            case .cloudIcon:
                CloudIcon()
                    .presentationDetents([.medium, .large])
                    .customPresentationCornerRadius(20)
            case .paywall:
                PaywallView()
                    .customPresentationCornerRadius(20)
            case .quickResponseCode(let text, let title, let preview):
                QuickResponseCodeview(text:text, title: title, preview:preview)
                    .presentationDetents([.medium])
                    .customPresentationCornerRadius(20)
            default:
                EmptyView()
                    .onAppear{
                        manager.sheetPage = .none
                    }
            }
        }
        .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
    }
    
    @ViewBuilder
    func firstStartLauchFirstStartView()-> some View{
        LauchFirstStartView(){
            withAnimation {
                self.firstStart.toggle()
            }
            
            self.servers.append(PushServerModel(url: BaseConfig.defaultServer))
            
            RealmManager.handler{ proxy in
                proxy.writeAsync {
                    proxy.add(Message.examples())
                }
            }
            
            
        }
        .background(.ultraThinMaterial)
    }
    
    func backgroundModeHandler(newValue: ScenePhase){
        
        manager.registerForRemoteNotifications()
        setLangAssistantPrompt()
        
        switch newValue{
        case .active:
            
            if manager.isWarmStart {
                Log.debug("🔥 热启动")
            } else {
                Log.debug("❄️ 冷启动")
                manager.isWarmStart  = true // 进入前台后，标记为热启动
                RealmManager.handler { proxy in
                    let groups = proxy.objects(ChatGroup.self)
                    proxy.writeAsync {
                        groups.setValue(false, forKey: "current")
                    }
                }
            }
            
            if let name = QuickAction.selectAction?.userInfo?["name"] as? String{
                QuickAction.selectAction = nil
                manager.page = .message
                switch name{
                case "allread":
                    RealmManager.handler { proxy in
                        let datas = proxy.objects(Message.self).where({!$0.read})
                        proxy.writeAsync {
                            datas.setValue(true, forKey: "read")
                        }
                        
                    }
                    Toast.success(title: String(localized: "操作成功"))
                case "alldelread","alldelnotread":
                    self.activeName = name
                    self.showAlart.toggle()
                default:
                    break
                }
            }
            
        case .background:
            UIApplication.shared.shortcutItems = QuickAction.allShortcutItems
            
        default:
            break
        }
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        RealmManager.handler { proxy in
            let datas = proxy.objects(Message.self).filter({$0.isExpired()})
            proxy.writeAsync {
                proxy.delete(datas)
            }
        }
    }
    
    func setLangAssistantPrompt(){
        if let currentLang  = Locale.preferredLanguages.first{
            if lang != currentLang {
                RealmManager.handler { realm in
                    let datas = realm.objects(ChatPrompt.self).where({$0.isBuiltIn})
                    try? realm.write{
                        realm.delete(datas)
                        realm.add(ChatPrompt.prompts)
                        DispatchQueue.main.async {
                            lang = currentLang
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func openUrlView(url: URL){
        
        let result = manager.outParamsHandler(address: url.absoluteString)
        
        switch result {
        case .text(_):
            break
        case .crypto(let text):
            Log.debug(text)
            DispatchQueue.main.async {
                manager.page = .setting
                manager.router = [.privacy, .crypto(text)]
            }
        case .server(let url):
            manager.appendServer(server: PushServerModel(url: url)) { _, msg in
                DispatchQueue.main.async {
                    manager.page = .setting
                    manager.router = [.server]
                }
                Toast.shared.present(title: msg, symbol: "document.viewfinder")
            }
        case .serverKey(let url, let key):
            manager.restore(address: url, deviceKey: key) { success in
                DispatchQueue.main.async {
                    manager.page = .setting
                    manager.router = [.server]
                }
                if !success{
                    Toast.error(title: String(localized: "key不正确"))
                }
            }
        case .assistant(let text):
            if let account = AssistantAccount(base64: text){
                DispatchQueue.main.async {
                    manager.page = .setting
                    manager.router = [.assistantSetting(account)]
                }
            }
        case .otherUrl( _):
            break
        }
        
    }
}



#Preview {
    ContentView()
        .environmentObject(manager: PushbackManager.shared, chatManager: openChatManager.shared, appstate: AppState.shared)
}
