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
    
    case widget(title:String?, data:String)
    
    case tts
}




enum TabPage :String{
    case message = "message"
    case setting = "setting"
}


struct EnvironmentObjectModifier:ViewModifier{
    
    var manager:PushbackManager?
    var chatManager:openChatManager?
    
    func body(content: Content) -> some View {
        content
            .if(manager != nil) { view in
                view.environmentObject(manager!)
            }
            .if(chatManager != nil) { view in
                view.environmentObject(chatManager!)
            }
        
    }
    
    
    
}

extension View{
    func router(_ manager:PushbackManager, chat:openChatManager, audio:AudioManager) -> some View{
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
                .env(manager, chat, audio)
                
                
            }
    }
    
    func env(_ manager:PushbackManager,_ chat:openChatManager,_ audio:AudioManager) -> some View{
        self
            .environmentObject(manager)
            .environmentObject(chat)
            .environmentObject(audio)
    }
}
