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
        
        .overlay{
            if let message = manager.selectMessage{
                SelectMessageView(message: message) {
                    withAnimation(.easeInOut){
                        manager.selectMessage = nil
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                .transition(.move(edge: .leading))
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
        .safeAreaInset(edge: .bottom) {
            if manager.speaking {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay { MusicInfo().transition(.move(edge: .leading)) }
                    .frame(height: 70)
                    .overlay(alignment: .bottom, content: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 1)
                    })
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
                    .shadow(radius: 3)
                    .padding(.horizontal, 5)
                    .animation(.easeInOut, value: manager.router)
                    .transition(.move(edge: .trailing))
            }
        }
        
    }
    
    @ViewBuilder
    func IphoneHomeView()-> some View{
        VStack(spacing: 0) {
            TabView(selection: $manager.page) {
                
                ForEach(TabPage.allCases, id: \.rawValue){ page in
                    
                    NavigationStack(path: $manager.router){
                        Group{
                            switch page{
                            case .message:
                                MessagePage()
                            case .assistant:
                                AssistantPageView()
                            case .example:
                                ExampleView()
                            case .setting:
                                SettingsPage()
                            }
                        }.router(manager)
                    }
                    .toolbar(.hidden, for: .tabBar)
                    .tag(page)
                    
                }
            }
            .onChange(of: manager.page) { page in
                Haptic.impact()
                if page != .assistant{
                    manager.oldPage = page
                }
            }
            if manager.router.count == 0 && manager.page != .assistant {
                GeometryReader {proxy in
                    CustomTabBar(size: proxy.size, activeTab: $manager.page, searchText: $manager.searchText) { search in
                        manager.isSearchActive = search
                    } onSearchTextFieldActive: { active in
                        
                    }
                    .transition(.move(edge: .bottom))
                    
                }
                .padding(.horizontal, 10)
                .frame( height: 56)
                .background(.ultraThickMaterial)
            }
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
                    if code.hasHttp(){
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
                        
                    case .assistantSetting(let account):
                        AssistantSettingsView(account: account)
                        
                    case .crypto(let text):
                        CryptoConfigView(config: text)
                        
                    case .server:
                        ServersConfigView()
                        
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
                .navigationBarTitleDisplayMode(.large)
                .environmentObject(manager)
               
                
                
            }
    }
    
}

#Preview {
    ContentView()
        .environmentObject(AppManager.shared)
}
