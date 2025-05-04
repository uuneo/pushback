//
//  RouterPageView.swift
//  pushback
//
//  Created by lynn on 2025/5/4.
//
import SwiftUI

// MARK: - Page model
enum SubPage: Equatable{
    case customKey
    case scan
    case appIcon
    case web(String)
    case cloudIcon
    case paywall
    case quickResponseCode(text:String,title: String?,preview: String?)
    case none
    
}


enum RouterPage: Hashable {
    case example
    case messageDetail(String)
    case assistant
    case sound
    case crypto(String?)
    
    
    case server
    case assistantSetting(AssistantAccount?)
    case privacy
    case more
}




enum TabPage :String{
    case message = "message"
    case setting = "setting"
}


struct RouterPageViewModifier:ViewModifier{
    var manager:PushbackManager
    var chatManager:openChatManager
    var appstate:AppState
    func body(content: Content) -> some View {
        content
            .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
            .navigationDestination(for: RouterPage.self){ router in
                Group{
                    switch router {
                    case .example:
                        ExampleView()
                            .toolbar(.hidden, for: .tabBar)
                    case .messageDetail(let group):
                        MessageDetailPage(group: group)
                            .navigationTitle(group)
                            .toolbar(.hidden, for: .tabBar)
                    case .sound:
                        SoundView()
                            .toolbar(.hidden, for: .tabBar)
                    case .assistant:
                        AssistantPageView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .tabBar)
                    case .crypto(let text):
                        CryptoConfigView(config: text)
                            .toolbar(.hidden, for: .tabBar)
                    case .server:
                        ServersConfigView()
                            .toolbar(.hidden, for: .tabBar)
                    case .assistantSetting(let account):
                        AssistantSettingsView(showClose: false, account: account)
                            .toolbar(.hidden, for: .tabBar)
                    case .privacy:
                        PrivacySecurity()
                            .toolbar(.hidden, for: .tabBar)
                    case .more:
                        MoreOperationsView()
                            .toolbar(.hidden, for: .tabBar)
                    }
                }
                .environmentObject(manager: manager, chatManager: chatManager, appstate: appstate)
               
            }
    }
}


struct EnvironmentObjectModifier:ViewModifier{
    
    var manager:PushbackManager?
    var chatManager:openChatManager?
    var appstate:AppState?
    
    func body(content: Content) -> some View {
        content
            .if(manager != nil) { view in
                view.environmentObject(manager!)
            }
            .if(chatManager != nil) { view in
                view.environmentObject(chatManager!)
            }
            .if(appstate != nil) { view in
                view.environmentObject(appstate!)
            }
        
    }
    
    
    
}

extension View{
    func router(manager: PushbackManager, chatManager: openChatManager, appstate: AppState) -> some View{
        modifier(RouterPageViewModifier(manager: manager, chatManager: chatManager, appstate: appstate))
    }
    
    func environmentObject(manager: PushbackManager? = nil, chatManager: openChatManager? = nil, appstate: AppState? = nil) -> some View{
        modifier(EnvironmentObjectModifier(manager: manager, chatManager: chatManager, appstate: appstate))
    }
}
