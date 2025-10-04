//
//  ContentView.swift
//  pushback
//
//  Created by lynn on 2025/4/3.
//

import SwiftUI
import GRDB
import UniformTypeIdentifiers
import WidgetKit
import Defaults


struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @Default(.showGroup) private var showGroup
    @StateObject private var manager = AppManager.shared
    @StateObject private var messageManager = MessagesManager.shared
    
    @Default(.firstStart) private var firstStart
    @Default(.badgeMode) private var badgeMode
    
    @State private var HomeViewMode:NavigationSplitViewVisibility = .detailOnly

    @Namespace private var selectMessageSpace

    var body: some View {
        
        ZStack{
            
            IphoneHomeView()
                .if(ISPAD) { IpadHomeView() }
            
            
            if firstStart{
                firstStartLauchFirstStartView()
            }
            
        }
        .environmentObject(manager)
        .overlay{
            if manager.isLoading && manager.inAssistant{
                ColoredBorder()
            }
        }
        .if( !Defaults[.firstStart] ){ view in
            Group{
                if #available(iOS 17.0, *) {
                    view
                        .subscriptionStatusTask(for: "21582431") {
                            if let result = $0.value {
                                let premiumUser = result.filter({ $0.state == .subscribed })
                                Log.info("User Subscribed = \(!premiumUser.isEmpty)")
                                manager.PremiumUser = !premiumUser.isEmpty
                            }
                        }
                } else {
                    // Fallback on earlier versions
                    view
                }
            }
            
        }
        .sheet(isPresented: manager.sheetShow){ ContentSheetViewPage() }
        .fullScreenCover(isPresented: manager.fullShow){ ContentFullViewPage() }
#if DEBUG
        .onAppear{
            manager.printDirectoryContents(at: CONTAINER!.path())
        }
#endif

    }
    
    @ViewBuilder
    func IphoneHomeView()-> some View{

        Group{
            if #available(iOS 26.0, *){
                TabView(selection: $manager.page) {

                    Tab(value: .message) {
                        NavigationStack(path: $manager.messageRouter){
                            // MARK: 信息页面
                            MessagePage()
                                .router(manager)

                        }
                    } label: {
                        Label( "消息", systemImage: "ellipsis.message")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }
                    .badge(messageManager.unreadCount)



                    Tab(value: .setting) {
                        NavigationStack(path: $manager.settingsRouter){
                            // MARK: 设置页面
                            SettingsPage().router(manager)

                        }
                    } label: {
                        Label( "设置", systemImage: "gear.badge.questionmark")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }


                    Tab(value: .search, role: .search) {
                        NavigationStack(path: $manager.searchRouter){
                            // MARK: 设置页面
                            SearchMessageView(searchText: $manager.searchText)
                                .router(manager)
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }

                }.tabBarMinimizeBehavior(.onScrollDown)
            }else{
                TabView(selection: $manager.page) {

                    NavigationStack(path: $manager.messageRouter){
                        // MARK: 信息页面
                        MessagePage().router(manager)

                    }
                    .tabItem {
                        Label( "消息", systemImage: "ellipsis.message")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)

                    }
                    .badge(messageManager.unreadCount)
                    .tag(TabPage.message)



                    NavigationStack(path: $manager.settingsRouter){
                        // MARK: 设置页面
                        SettingsPage().router(manager)

                    }
                    .tabItem {
                        Label( "设置", systemImage: "gear.badge.questionmark")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, .primary)
                    }
                    .tag(TabPage.setting)


                }
            }
        }
        .onChange(of: manager.page) { _ in
            Haptic.impact()
        }
    }
    
    @ViewBuilder
    func IpadHomeView() -> some View{
        
        NavigationSplitView(columnVisibility: $HomeViewMode) {
            SettingsPage()
                .environmentObject(manager)
        } detail: {
            
            NavigationStack(path: $manager.messageRouter){
                MessagePage()
                    .router(manager)
            }
        }
    }
    
    @ViewBuilder
    func firstStartLauchFirstStartView()-> some View{
        PermissionsStartView(){
            withAnimation {
                self.firstStart.toggle()
            }
            
            Task.detached(priority: .userInitiated) {
                for item in DatabaseManager.examples(){
                    await  DatabaseManager.shared.add(item)
                }
            }
            
        }
        .background(.ultraThinMaterial)
    }
    
    @ViewBuilder
    func ContentFullViewPage() -> some View{
        Group{
            switch manager.fullPage {
            case .customKey:
                ChangeKeyView()
            case .scan:
                ScanView{ code in
                    if let data = AppManager.shared.HandlerOpenUrl(url: code){
                        manager.fullPage = .none
                        AppManager.shared.sheetPage =
                            .quickResponseCode(
                                text: data,
                                title: String(localized: "二维码"),
                                preview: nil
                            )
                    }
                    manager.fullPage = .none
                    return false
                }
            case .web(let url):
                SFSafariView(url: url).ignoresSafeArea()

            default:
                EmptyView().onAppear{  manager.fullPage = .none }
            }
        }
        .environmentObject(manager)
        
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
                CloudIcon() .presentationDetents([.medium, .large])
            case .paywall:
                if #available(iOS 18.0, *) { PayWallHighView() }else{
                    EmptyView()
                        .onAppear{ manager.sheetPage = .none }
                }
            case .quickResponseCode(let text, let title, let preview):
                QuickResponseCodeview(text:text, title: title, preview:preview)
                    .presentationDetents([.medium])
            case .scan:
                ScanView{ code in
                    if let data = AppManager.shared.HandlerOpenUrl(url: code){
                        if data.hasHttp(){
                            let success = await manager.appendServer(server: PushServerModel(url: data))
                            if success{
                                manager.sheetPage = .none
                                manager.fullPage = .none
                                manager.page = .setting
                                manager.settingsRouter = [.server]
                                return false
                            }

                        }
                    }
                    return true
                }
            case .crypto(let item):
                ChangeCryptoConfigView(item: item)
                   
            default:
                EmptyView().onAppear{ manager.sheetPage = .none }
            }
        }
        .environmentObject(manager)
        .customPresentationCornerRadius(30)
    }
    
}

extension View{
    func router(_ manager:AppManager) -> some View{
        self
            .navigationDestination(for: RouterPage.self){ router in
                Group{
                    switch router {
                    case .example:
                        ExampleView()
                        
                    case .messageDetail(let group):
                        MessageDetailPage(group: group)
                            .navigationTitle(group)
                        
                    case .sound:
                        SoundView()

                    case .assistant:
                        AssistantPageView()
                        
                    case .assistantSetting(let account):
                        AssistantSettingsView(account: account)
                        
                    case .crypto:
                        CryptoConfigListView()
                        
                    case .server:
                        ServersConfigView()
                        
                    case .more:
                        MoreOperationsView()
                        
                    case .widget(title: let title, data: let data):
                        WidgetChartView(data: data)
                            .navigationTitle(title ?? "小组件")
                    case .tts:
                        SpeakSettingsView()
                        
                    case .pushtalk:
                        PushToTalkView()
                        
                    case .about:
                        AboutNoLetView()

                    case .dataSetting:
                        DataSettingView()
                        
                    case .serverInfo(let server):
                        ServerMonitoringView(server: server)

                    case .files:
                        NoletFileList()

                    }
                }
                .toolbar(.hidden, for: .tabBar)
                .navigationBarTitleDisplayMode(.large)
                .environmentObject(manager)
                
                
                
            }
    }
    
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
