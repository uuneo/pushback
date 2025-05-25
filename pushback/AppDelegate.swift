//
//  AppDelegate.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import Foundation
import UIKit
import PushKit
import SwiftyJSON
import Defaults
import SwiftUI
import AppIntents




class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    
    
    func setupRealm() {
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
        
#if DEBUG
        let realm = try? Realm()
        Log.debug("message count: \(realm?.objects(Message.self).count ?? 0)")
#endif
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        Defaults[.deviceToken] = token
        AppManager.shared.registers()
        CloudManager.shared.getUserId()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // MARK:  处理注册失败的情况
        Log.debug(error)
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        /// 配置数据库
        setupRealm()
        
        UNUserNotificationCenter.current().delegate = self
        
        
        let copyAction =  UNNotificationAction(identifier: Identifiers.copyAction,
                                               title: String(localized: "复制"),
                                               options: [.foreground],
                                               icon: .init(systemImageName: "doc.on.doc"))
        
        
        let muteAction =  UNNotificationAction(identifier: Identifiers.muteAction,
                                               title: String(localized: "静音分组1小时"),
                                               options: [.foreground ],
                                               icon: .init(systemImageName: "speaker.slash"))
        
        // 创建 category
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: Identifiers.reminderCategory,
                                   actions: [copyAction,muteAction],
                                   intentIdentifiers: [],
                                   options: [.hiddenPreviewsShowTitle])
        ])
        
        
        return true
    }
    
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let selectAction = options.shortcutItem{
            QuickAction.selectAction = selectAction
        }
        let sceneonfiguration = UISceneConfiguration(name: "Quick Action Scene", sessionRole: connectingSceneSession.role)
        sceneonfiguration.delegateClass = QuickActionSceneDelegate.self
        return sceneonfiguration
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let content = response.notification.request.content
        Log.debug(content)
        
        AppManager.shared.page = .message
        AppManager.shared.router = []
        DispatchQueue.main.async{
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
        AppManager.shared.page = .setting
        AppManager.shared.router = [.more]
    }
    
}


class QuickActionSceneDelegate:UIResponder,UIWindowSceneDelegate{
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        QuickAction.selectAction = shortcutItem
    }
}
