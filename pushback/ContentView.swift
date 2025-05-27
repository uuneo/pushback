//
//  ContentView.swift
//  pushback
//
//  Created by lynn on 2025/4/3.
//


import SwiftUI
import GRDB
import Defaults
import UniformTypeIdentifiers
import WidgetKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var manager: AppManager
    @StateObject private var messageManager = MessagesManager.shared
    
    @Default(.servers) private var servers
    @Default(.firstStart) private var firstStart
    @Default(.badgeMode) private var badgeMode
    @Default(.lang) private var lang
    @State private var HomeViewMode:NavigationSplitViewVisibility = .detailOnly
    @State private var showAlart:Bool = false
    @State private var activeName:String = ""
    @State private var messagesPath: [String] = []
    @State private var selectableText = true
    
    @State private var expandSheet: Bool = false
    
    var body: some View {
        
        ZStack{
            
            IphoneHomeView()
                .if(ISPAD) { IpadHomeView() }
            
            if firstStart{
                firstStartLauchFirstStartView()
            }
            
            
        }
        
        .onChange(of: scenePhase, perform: self.backgroundModeHandler)
        .onOpenURL(perform: self.openUrlView)
        .alert(isPresented: $showAlart) {
            Alert(title: Text( "操作不可逆!"), message: Text("是否确认删除所有已读消息!"), primaryButton: .destructive( Text("删除"),  action: {
                MessagesManager.shared.delete(allRead: true)
            }), secondaryButton: .cancel()) }
//
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
                MessagePage().router(manager)
                
            }
            .badge(messageManager.unreadCount)
            .tabItem {
                Label( "消息", systemImage: "ellipsis.message")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .green, colorScheme == .dark ? Color.white : Color.black)
            }
            .tag(TabPage.message)
            
            
            
            NavigationStack(path: $manager.router){
                // MARK: 设置页面
                SettingsPage().router(manager)
                
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
        
        NavigationSplitView(columnVisibility: $HomeViewMode) {
            SettingsPage()
                .environmentObject(manager)
        } detail: {
            
            NavigationStack(path: $manager.router){
                MessagePage()
                    .router(manager)
            }
        }
    }
    
    
    @ViewBuilder
    func firstStartLauchFirstStartView()-> some View{
        LauchFirstStartView(){
            withAnimation {
                self.firstStart.toggle()
            }
            if self.servers.count == 0{
                Task{
                    await manager.appendServer(server: PushServerModel(url: BaseConfig.defaultServer))
                }
            }
            
            // TODO: 添加example
            for item in MessagesManager.examples(){
                MessagesManager.shared.add(item)
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
                manager.isWarmStart = true // 进入前台后，标记为热启动
                do {
                    try DatabaseManager.shared.dbQueue.write { db in
                        // 1. 将所有 ChatGroup 的 current 设为 false
                        try ChatGroup.updateAll(db,
                                                ChatGroup.Columns.current.set(to: false))

                        // 2. 查找无关联 ChatMessage 的 ChatGroup
                        let allGroups = try ChatGroup.fetchAll(db)
                        var deleteList: [ChatGroup] = []

                        for group in allGroups {
                            let messageCount = try ChatMessage
                                .filter(ChatMessage.Columns.chat == group.id)
                                .fetchCount(db)

                            if messageCount == 0 {
                                deleteList.append(group)
                            }
                        }

                        // 3. 删除无消息的 ChatGroup
                        if !deleteList.isEmpty {
                            for group in deleteList {
                                try group.delete(db)
                            }
                        }
                    }
                } catch {
                    print("GRDB 错误: \(error)")
                }

            }
            
            if let name = QuickAction.selectAction?.type{
            
                QuickAction.selectAction = nil
                manager.page = .message
                switch name{
                case QuickAction.assistant.rawValue:
                    manager.router = [.assistant]
                case QuickAction.alldelread.rawValue:
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
        UNUserNotificationCenter.current().setBadgeCount(messageManager.unreadCount())
        WidgetCenter.shared.reloadAllTimelines()
        MessagesManager.shared.deleteExpired()
    }
    
    func setLangAssistantPrompt(){
        if let currentLang  = Locale.preferredLanguages.first{
            if lang != currentLang {
                try? DatabaseManager.shared.dbQueue.write { db in
                    // 删除 inside == true 的项
                    try ChatPrompt.filter(ChatPrompt.Columns.inside == true).deleteAll(db)
                    
                    // 添加默认 prompts
                    for prompt in ChatPrompt.prompts {
                        try prompt.insert(db)
                    }
                    
                    // 回到主线程设置语言
                    DispatchQueue.main.async {
                        lang = currentLang
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
            Task{
                let success = await manager.appendServer(server: PushServerModel(url: url))
                if success{
                    DispatchQueue.main.async {
                        manager.page = .setting
                        manager.router = [.server]
                    }
                }
            }
        case .serverKey(let url, let key):
            Task{
                let success = await manager.restore(address: url, deviceKey: key)
                if success{
                    DispatchQueue.main.async {
                        manager.page = .setting
                        manager.router = [.server]
                    }
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
            case .widget:
                DispatchQueue.main.async {
                    manager.page = .setting
                    manager.router = [.more, .widget(title: title, data: data)]
                }
            case .icon:
                manager.page = .setting
                manager.sheetPage = .cloudIcon
            }
        default:
            break
            
        }
        
    }
 
}



#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
