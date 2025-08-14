//
//  SceneDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import SwiftUI
import WidgetKit
import GRDB
import Defaults

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var overlayWindow: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let hosting = UIHostingController(rootView: ContentView())
       
        self.window?.rootViewController = hosting
        window?.makeKeyAndVisible()
        // 2. 添加 overlay window（如 Toast 层）
        if overlayWindow == nil {
            let overlay = PassthroughWindow(windowScene: windowScene)
            overlay.backgroundColor = .clear
            
            let toastController = UIHostingController(rootView: ToastGroup())
            toastController.view.backgroundColor = .clear
            toastController.view.frame = windowScene.coordinateSpace.bounds
            
            overlay.rootViewController = toastController
            overlay.isHidden = false
            overlay.isUserInteractionEnabled = true
            overlay.tag = 1009
            
            overlayWindow = overlay
        }
        
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url
            // 处理这个 URL
            AppManager.shared.HandlerOpenUrl(url: url)
        }
        
    }
    
    
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        let manager = AppManager.shared
        
        manager.page = .message
        switch shortcutItem.type{
        case QuickAction.assistant.rawValue:
            manager.router = [.assistant]
        default:
            break
        }
        
        completionHandler(true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        let manager = AppManager.shared
        if !manager.isWarmStart{
            Log.debug("❄️ 冷启动")
            manager.isWarmStart = true // 进入前台后，标记为热启动
            openChatManager.shared.clearunuse()
            
        }
        Task.detached(priority: .userInitiated) {
            await MessagesManager.shared.updateGroup()
        }
        
        
        setLangAssistantPrompt()
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        UIApplication.shared.shortcutItems = QuickAction.allShortcutItems(showAssistant: Defaults[.assistantAccouns].count > 0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(DatabaseManager.shared.unreadCount())
        WidgetCenter.shared.reloadAllTimelines()
        Task.detached(priority: .userInitiated) {
            await DatabaseManager.shared.deleteExpired()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
    func setLangAssistantPrompt(){
        if let currentLang  = Locale.preferredLanguages.first{
           
            if Defaults[.lang] != currentLang{
                Task.detached(priority: .background) {
                    try await DatabaseManager.shared.dbPool.write { db in
                        // 删除 inside == true 的项
                        try ChatPrompt.filter(ChatPrompt.Columns.inside == true).deleteAll(db)
                        
                        // 添加默认 prompts
                        for prompt in ChatPrompt.prompts {
                            try prompt.insert(db)
                        }
                        
                        // 回到主线程设置语言
                         DispatchQueue.main.async {
                             Defaults[.lang] = currentLang
                        }
                    }
                }
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        AppManager.shared.HandlerOpenUrl(url: url)
    }
}


