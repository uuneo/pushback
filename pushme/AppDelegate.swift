//
//  AppDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import Defaults
import PushKit


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate{
    private var pushRegistry: PKPushRegistry = PKPushRegistry(queue: .main)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        
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
 
        if Defaults[.id] == ""{
            let id = KeychainHelper.shared.getDeviceID()
            Defaults[.id] = id
            Defaults[.user].id = id
        }
        
        return true
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.asHexString
        Defaults.setToken(token: token)
        
        let manager = AppManager.shared
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
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.asHexString
        Defaults.setToken(voip: token)
    }
    
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("收到通知")
        let manager = CallMainManager.shared.manager
        manager.reportNew(uuid: UUID(), callerName: "CallKit") {
            completion()
        }
        AppManager.shared.sheetPage = .none
        let callUser = CallUser(id: UUID().uuidString, name: "张三F", caller: "100", deviceToken: "", voipToken: "", voip: 1)
        
        AppManager.shared.fullPage = .answer(callUser)

       
        Thread.sleep(forTimeInterval: 0.1
        )
        completion()
        
    }
    
}


extension Data {
    // Convenience method to convert `Data` to a hex `String`.
    fileprivate var asHexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}


fileprivate extension Defaults{
    static func setToken(token: String? = nil, voip: String? = nil){
        
        self[.user].voip = BaseConfig.isVoip()
        
        if let token {
            self[.deviceToken] = token
            self[.user].deviceToken = token
            
            Task.detached(priority: .background) {
                let success = await CallCloudManager.shared.save(self[.user])
                if !success {
                    Toast.error(title: "上传令牌失败")
                }
            }
        }
        
        if let voip {
            Self[.voipDeviceToken] = voip
            Self[.user].voipToken = voip
        }
    }
}
