//
//  AppDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import Defaults

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        
        let actions = [ UNNotificationAction(identifier: Identifiers.copyAction,
                                             title:  String(localized: "复制"),
                                             options: [.foreground],
                                             icon: .init(systemImageName: "doc.on.doc")),
                        
                        UNNotificationAction(identifier: Identifiers.muteAction,
                                             title:  String(localized: "静音分组1小时"),
                                             options: [.foreground ],
                                             icon: .init(systemImageName: "speaker.slash")) ]
        
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: Identifiers.reminderCategory,
                                   actions: actions,
                                   intentIdentifiers: [],
                                   options: [.hiddenPreviewsShowTitle])
        ])
        
        if !Defaults[.firstStart] {
            AppManager.shared.registerForRemoteNotifications()
        }
        
        return true
    }
    
    
    
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        let manager = AppManager.shared
        
        Defaults[.deviceToken] = token
        CloudManager.shared.getUserId()
        
        if Defaults[.servers].count == 0{
            Task.detached(priority: .userInitiated) {
                _ = await manager.appendServer(server: PushServerModel(url: BaseConfig.defaultServer))
            }
        }else{
            manager.registers()
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        if let selectAction = options.shortcutItem{
            QuickAction.selectAction = selectAction
        }
        let sceneonfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        
        return sceneonfiguration
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let content = response.notification.request.content
        
        
        DispatchQueue.main.async{
            AppManager.shared.page = .message
            AppManager.shared.router = []
            AppManager.shared.selectId = response.notification.request.content.targetContentIdentifier
            AppManager.shared.selectGroup = content.threadIdentifier
        }
        
        notificatonHandler(userInfo: content.userInfo)
        
        // 清除通知中心的显示
        center.removeDeliveredNotifications(withIdentifiers: [content.threadIdentifier])
        
        
        completionHandler()
    }
    
    
    
    // 处理应用程序在前台是否显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 由于AppGroup消息通知存在延迟，手动通知一下
        Task.detached(priority: .background) {
            await  MessagesManager.shared.updateGroup()
        }
        
        if notification.request.content.interruptionLevel.rawValue > 1{
            completionHandler(.banner)
        }else{
            completionHandler(.badge)
        }
        
        notificatonHandler(userInfo: notification.request.content.userInfo)
    }
    
    func notificatonHandler(userInfo: [AnyHashable : Any]){
        if let urlStr = userInfo[Params.url.name] as? String, let url = URL(string: urlStr) {
            AppManager.openUrl(url: url)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        DispatchQueue.main.async{
            AppManager.shared.page = .setting
            AppManager.shared.router = [.more]
        }
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        AppManager.shared.registerForRemoteNotifications()
        
        
        sendImmediateNotification(title: "Token Update")
        
        completionHandler(.newData)
    }
    
    
    func sendImmediateNotification(title: String) {
        // 请求权限（如果还没请求过）
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            // 创建通知内容
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = Date().formatString()
            
            // 创建并添加请求
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content,trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }
}


