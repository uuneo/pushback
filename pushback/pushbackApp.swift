//
//  pushbackApp.swift
//  pushback
//
//  Created by lynn on 2025/4/3.
//


import SwiftUI
import OpenAI
@main
struct pushbackApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { WindowGroup { RootView{ ContentView() } } }
}


/// Root View for Creating Overlay Window
struct RootView<Content: View>: View {
    @ViewBuilder var content: Content
    /// View Properties
    @State private var overlayWindow: UIWindow?
    @StateObject private var manager = AppManager.shared
    
    var body: some View {
        content
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
                }
            }
            .overlay{
                if manager.isLoading && manager.inAssistant{
                    ColoredBorder()
                }
            }
            .if( true ){ view in
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
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
                    let window = PassthroughWindow(windowScene: windowScene)
                    window.backgroundColor = .clear
                    /// View Controller
                    let rootController = UIHostingController(rootView: ToastGroup())
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    window.rootViewController = rootController
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    
                    overlayWindow = window
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

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if AppManager.shared.selectMessage == nil{
            AppManager.shared.selectPoint = point
        }
        guard let hitView = super.hitTest(point, with: event),
                let rootView = rootViewController?.view
        else { return nil }
        
        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of rootview's is receving hit test
                let pointInSubView = subview.convert(point, from: rootView)
                if subview.hitTest(pointInSubView, with: event) != nil {
                    return hitView
                }
            }
            
            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
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




