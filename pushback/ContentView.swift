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
import WidgetKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var manager = PushbackManager.shared
    @StateObject private var audioManager = AudioManager.shared
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
    @State private var selectableText = true
    
    @State private var expandSheet: Bool = false
    
    var body: some View {
        
        ZStack{
            if #available(iOS 17.0, *) {
                IphoneHomeView().if(ISPAD) { IpadHomeView() }
                    .subscriptionStatusTask(for: "21582431") {
                        if let result = $0.value {
                            let premiumUser = result.filter({ $0.state == .subscribed })
                            Log.info("User Subscribed = \(!premiumUser.isEmpty)")
                            manager.PremiumUser = !premiumUser.isEmpty
                        }
                    }
                
            }else{
                IphoneHomeView().if(ISPAD) { IpadHomeView() }
            }
            if firstStart{
                firstStartLauchFirstStartView()
            }
            
            
        }
        .environmentObject(manager)
        .safeAreaInset(edge: .bottom) {
            if audioManager.speaking {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        /// Music Info
                        MusicInfo()
                            .environmentObject(audioManager)
                    }
                
                    .frame(height: 70)
                /// Separator Line
                    .overlay(alignment: .bottom, content: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 1)
                    })
                /// 49: Default Tab Bar Height
                    .offset(y: manager.router.count == 0 ? -49 : 0)
                    .animation(.easeInOut, value: manager.router)
                    .transition(.move(edge: .leading))
                    
            }
        }
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
        .alert(isPresented: $showAlart) {
            Alert(title: Text( "操作不可逆!"), message: Text("是否确认删除所有已读消息!"), primaryButton: .destructive( Text("删除"),  action: {
                
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({$0.read})
                    proxy.writeAsync {
                        proxy.delete(datas)
                    }
                }
            }), secondaryButton: .cancel()) }
        .task {
            for await value in Defaults.updates(.servers) {
                try? await Task.sleep(for: .seconds(1))
                await manager.registers()
                PushServerCloudKit.shared.updatePushServers(items: value)
            }
        }
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
                MessagePage().router(manager, chat: chatManager, audio: audioManager)
                
            }
            .badge(messages.where({!$0.read}).count)
            .tabItem {
                Label( "消息", systemImage: "ellipsis.message")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .green, colorScheme == .dark ? Color.white : Color.black)
            }
            .tag(TabPage.message)
            
            
            
            NavigationStack(path: $manager.router){
                // MARK: 设置页面
                SettingsPage().router(manager, chat: chatManager, audio: audioManager)
                
            }
            .tabItem {
                Label( "设置", systemImage: "gear.badge.questionmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .green, colorScheme == .dark ? Color.white : Color.black)
            }
            .tag(TabPage.setting)
            
        }
        
        
        
    }
    
    @ViewBuilder
    func IpadHomeView() -> some View{
        
        NavigationSplitView(columnVisibility: $noShow) {
            SettingsPage()
                .env(manager, chatManager, audioManager)
        } detail: {
            
            NavigationStack(path: $manager.router){
                MessagePage()
                    .router(manager, chat: chatManager, audio: audioManager)
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
        .env(manager, chatManager, audioManager)
        
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
                if #available(iOS 18.0, *) {
                
                    PayWallHighView()
                        .customPresentationCornerRadius(20)
                }
                
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
        .env(manager, chatManager, audioManager)
    }
    
    @ViewBuilder
    func firstStartLauchFirstStartView()-> some View{
        LauchFirstStartView(){
            withAnimation {
                self.firstStart.toggle()
            }
            if self.servers.count == 0{
                self.servers.append(PushServerModel(url: BaseConfig.defaultServer))
            }
            
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
            
            if !manager.isWarmStart{
                Log.debug("❄️ 冷启动")
                manager.isWarmStart  = true // 进入前台后，标记为热启动
                RealmManager.handler { proxy in
                    let groups = proxy.objects(ChatGroup.self)
                    proxy.writeAsync {
                        groups.setValue(false, forKey: "current")
                    }
                    
                    var deleteList:[ChatGroup] = []
                    
                    for group in groups {
                        if proxy.objects(ChatMessage.self).where({$0.chat == group.id }).count == 0{
                            deleteList.append(group)
                        }
                    }
                    
                    if deleteList.count > 0{
                        try? proxy.write{
                            proxy.delete(deleteList)
                        }
                    }
                    
                }
                
                
            }
            
            if let name = QuickAction.selectAction?.userInfo?["name"] as? String{
                QuickAction.selectAction = nil
                manager.page = .message
                switch name{
                case "assistant":
                    manager.router = [.assistant]
                case "alldelread":
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
        
        WidgetCenter.shared.reloadAllTimelines()
        
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
    
        switch manager.outParamsHandler(address: url.absoluteString) {
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
                    manager.router = [.assistant,.assistantSetting(account)]
                }
            }
        case .page(page: let page,title: let title, data: let data):
            switch page{
            case "widget":
                DispatchQueue.main.async {
                    manager.page = .setting
                    manager.router = [.more, .widget(title: title, data: data)]
                }
            case "icon":
                manager.page = .setting
                manager.sheetPage = .cloudIcon
            default:
                break
            }
        default:
            break
            
        }
        
    }
 
}



#Preview {
    ContentView()
        .environmentObject( PushbackManager.shared)
}
