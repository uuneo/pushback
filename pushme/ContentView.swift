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
  
    
    @StateObject private var manager = AppManager.shared
    @StateObject private var messageManager = MessagesManager.shared
    
    @Default(.firstStart) private var firstStart
    @Default(.badgeMode) private var badgeMode
    
    @State private var HomeViewMode:NavigationSplitViewVisibility = .detailOnly
    
    var body: some View {
        
        ZStack{
            
            IphoneHomeView()
                .if(ISPAD) { IpadHomeView() }
                
            if firstStart{
                firstStartLauchFirstStartView()
            }
            
            
        }
        .environmentObject(manager)
        .safeAreaInset(edge: .bottom) {
            if manager.speaking {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay { MusicInfo() }
                    .frame(height: 70)
                /// Separator Line
                    .overlay(alignment: .bottom, content: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 1)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 3)
                    .padding(.horizontal)
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
                .ignoresSafeArea(.all, edges: .top)
                .transition(.move(edge: .bottom))
            }
        }
        
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
        .sheet(isPresented: manager.sheetShow){ ContentSheetViewPage().customPresentationCornerRadius(20) }
        .fullScreenCover(isPresented: manager.fullShow){ ContentFullViewPage() }
        .alert(isPresented: $manager.showHomeAlert) {
            Alert(title: Text( "操作不可逆!"), message: Text("是否确认删除所有已读消息!"), primaryButton: .destructive( Text("删除"),  action: {
                Task.detached(priority: .userInitiated) {
                    await DatabaseManager.shared.delete(allRead: true)
                }
            }), secondaryButton: .cancel()) }
//        .task {
//            
//            Task.detached(priority: .userInitiated) {
//                await DatabaseManager.CreateStresstest(max: 100000)
//            }
//
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
            manager.registerForRemoteNotifications()
            
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
                    if code.isValidURL() == .remote{
                        let success = await manager.appendServer(server: PushServerModel(url: code))
                        if success{
                            manager.router = [.server]
                        }
                        return success
                    }
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
                NavigationStack{ AppIconView() }.presentationDetents([.height(300)])
            case .cloudIcon:
                CloudIcon() .presentationDetents([.medium, .large])
            case .paywall:
                if #available(iOS 18.0, *) { PayWallHighView() }
            case .quickResponseCode(let text, let title, let preview):
                QuickResponseCodeview(text:text, title: title, preview:preview).presentationDetents([.medium])
            default:
                EmptyView().onAppear{ manager.sheetPage = .none }
            }
        }
        .environmentObject(manager)
        .customPresentationCornerRadius(20)
    }
    
}


@available(iOS 16.0, *)
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
                            .navigationBarBackButtonHidden()
                    case .crypto(let text):
                        CryptoConfigView(config: text)
                        
                    case .server:
                        ServersConfigView()
                        
                    case .assistantSetting(let account):
                        AssistantSettingsView(account: account)
                    case .privacy:
                        PrivacySecurity()
                        
                    case .more:
                        MoreOperationsView()
                        
                    case .widget(title: let title, data: let data):
                        WidgetChartView(data: data)
                            .navigationTitle(title ?? "小组件")
                    case .tts:
                        SpeakSettingsView()
                       
                    }
                }
                .toolbar(.hidden, for: .tabBar)
                .environmentObject(manager)
               
                
                
            }
    }
    
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
