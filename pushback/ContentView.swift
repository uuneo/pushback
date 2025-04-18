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
    @EnvironmentObject private var manager:PushbackManager
    @StateObject private var chatManager = openChatManager.shared
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
                firstStartLauchFirstStartView()
            }
            
        }
        .sheet(isPresented: manager.sheetShow){ ContentSheetViewPage() .customPresentationCornerRadius(20) }
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
                            
                            
                            if activeName == "alldelnotread"{
                                RealmManager.handler { proxy in
                                    let datas = proxy.objects(Message.self).where({!$0.read})
                                    proxy.writeAsync {
                                        datas.setValue(true, forKey: "read")
                                    }
                                }
                            }
                           
                            
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
//        .task{
//            autoreleasepool {
//                var messages:[Message] = []
//                
//                for index in 0...10000{
//                    messages.append(contentsOf: Message.examples(group: "\(index % 5)"))
//                }
//                
//                RealmManager.handler { proxy in
//                    proxy.writeAsync {
//                        proxy.add(messages)
//                    }
//                   
//                }
//            }
//        }
//        
     
        
    }
    
    
    @ViewBuilder
    func IphoneHomeView()-> some View{
            TabView(selection: Binding(get: {
                manager.page
            }, set: { value in
                manager.page = value
            })) {
                
               
                
               
                // MARK: 信息页面
                MessagePage()
                    .badge(messages.where({!$0.read}).count)
                    .tabItem {
                        Label( "消息", systemImage: "ellipsis.message")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .green, tabColor2)
                    }
                    .tag(TabPage.message)
                
                
                // MARK: 设置页面
                SettingsPage()
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
        } detail: {
            MessagePage()
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
            NavigationStack{
                SoundView()
            }
        case .scan:
            ScanView()
        case .web(let url):
            SFSafariView(url: url)
                .ignoresSafeArea()
        case .crash(let crashlog):
            CrashReportView(crashLog: crashlog)
        case .assistant:
            NavigationStack{
                AssistantPageView()
                    .navigationBarBackButtonHidden()
                    .toolbar(.hidden, for: .tabBar)
                    .transition(.slide)
                    .animation(.default, value: manager.fullPage)
            }
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
            
        case .crash(let crashlog):
            CrashReportView(crashLog: crashlog)
            
        case .chatgpt(let id):
            NavigationStack{
                
                AssistantPageView()
                    .onAppear{
                        chatManager.messageId = id
                        
                        RealmManager.handler { proxy in
                            let datas = proxy.objects(ChatGroup.self)
                            let groups = datas.where({$0.id != id})
                            let current =  datas.where({$0.id == id})
                            proxy.writeAsync {
                                groups.setValue(false, forKey: "current")
                                current.setValue(true, forKey: "current")
                            }
                        }
                    }
            }
            
        case .cloudIcon:
            CloudIcon()
                .presentationDetents([.height(300),.medium, .large])
                .customPresentationCornerRadius(20)
        default:
            EmptyView()
                .onAppear{
                    manager.sheetPage = .none
                }
        }
    }
    
    @ViewBuilder
    func firstStartLauchFirstStartView()-> some View{
        LauchFirstStartView(){
            withAnimation {
                self.firstStart.toggle()
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
                    Log.debug(failure)
                    Toast.error(title: String(localized: "没有找到历史服务器"))
                    self.servers.append(PushServerModel(url: BaseConfig.defaultServer))
                }
                
                
            }

            RealmManager.handler{ proxy in
                proxy.writeAsync {
                    proxy.add(Message.examples())
                }
            }
            
            
        }
        .background(.ultraThinMaterial)
    }
    
    func openUrlView(url: URL){
        guard let scheme = url.scheme,
              let host = url.host(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else{ return }
        
        let params = components.getParams()
        Log.debug(scheme, host, params)
        // scheme = "mw" host = "fromLocalImage" params = ["key": "1233"]
        if host == "addServer"{
            if let url = params["url"], let _ = URL(string: url) {
                manager.appendServer(server: PushServerModel(url: url)) { result, msg in
                    manager.fullPage = .servers
                    
                    Toast.shared.present(title: msg, symbol: "document.viewfinder")
                }
            }else{
                Toast.info(title: String(localized: "参数错误"))
            }
        }else if host == "fromLocalImage",let _ = params["key"]{
            manager.fullPage = .imageCache
        }
    }
    
    func backgroundModeHandler(newValue: ScenePhase){
        
        manager.registerForRemoteNotifications()
        
        switch newValue{
        case .active:
            
            
            if manager.isWarmStart {
                Log.debug("🔥 热启动")
            } else {
                Log.debug("❄️ 冷启动")
                manager.isWarmStart  = true // 进入前台后，标记为热启动
                RealmManager.handler { proxy in
                    if let group = proxy.objects(ChatGroup.self).first(where: {$0.current}){
                        proxy.writeAsync {
                            group.current = false
                        }
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
    
}

#Preview {
    ContentView()
        .environmentObject(PushbackManager.shared)
}
