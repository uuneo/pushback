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
    
    @EnvironmentObject private var manager: AppManager
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var chatManager: openChatManager
    
    @EnvironmentObject private var groupModel: MessagesData
    
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
                
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({$0.read})
                    proxy.writeAsync {
                        proxy.delete(datas)
                    }
                }
            }), secondaryButton: .cancel()) }
//        .task {
//            Task.detached(priority: .background) {
//                if let realm = try? Realm() {
//                    var datas:[Message] = []
//                    for k in 0...33335{
//                        print(k)
//                        datas += RealmManager.examples().compactMap({
//                            $0.group = "\(k % 10)\($0.group)"
//                            return $0
//                        })
//                    }
//                    try? realm.write{
//                        realm.add(datas)
//                    }
//                }
//            }
//        }
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
                    .router(manager, chat: chatManager, audio: audioManager,message: groupModel)

                
            }
            .badge(groupModel.unReadCount)
            .tabItem {
                Label( "消息", systemImage: "ellipsis.message")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .green, colorScheme == .dark ? Color.white : Color.black)
            }
            .tag(TabPage.message)
            
            
            
            NavigationStack(path: $manager.router){
                // MARK: 设置页面
                SettingsPage()
                    .router(manager, chat: chatManager, audio: audioManager,message: groupModel)
                
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
                .env(manager, chatManager, audioManager, groupModel)
                .environmentObject(groupModel)
        } detail: {
            
            NavigationStack(path: $manager.router){
                MessagePage()
                    .router(manager, chat: chatManager, audio: audioManager, message: groupModel)
                    .environmentObject(groupModel)
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
            
            RealmManager.handler{ proxy in
                proxy.writeAsync {
                    proxy.add(RealmManager.examples())
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
                manager.isWarmStart = true // 进入前台后，标记为热启动
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
        
        WidgetCenter.shared.reloadAllTimelines()
        
        RealmManager.handler { proxy in
            let results = proxy.objects(Message.self)
            let datas = results.filter({$0.isExpired()})
            proxy.writeAsync {
                proxy.delete(datas)
            }
            if Defaults[.badgeMode] == .auto{
                let unRead = results.where({!$0.read}).count
                UNUserNotificationCenter.current().setBadgeCount( unRead == 0 ? -1 : unRead )
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
        .env(AppManager.shared, openChatManager.shared, AudioManager.shared, MessagesData.shared)
}
