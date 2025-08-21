//
//  AppDelegate.swift
//  pushme
//
//  Created by lynn on 2025/6/2.
//

import UIKit
import Defaults
import PushToTalk
import AVFAudio

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate{
    
    private let pttManager = PTTManager.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
       
        Identifiers.setCategories()
        // 预防用户切换系统语言导致语言不匹配
        Multilingual.resetTransLang()
        
        if !Defaults[.firstStart] {
            AppManager.shared.registerForRemoteNotifications()
        }
        
 
        if Defaults[.id] == ""{
            Defaults[.id] = KeychainHelper.shared.getDeviceID()
        }
        Task{
            do{
                self.pttManager.channelManager = try await PTChannelManager.channelManager(delegate: self, restorationDelegate: self)
                try await self.pttManager.channelManager?.setServiceStatus(.ready, channelUUID: self.pttManager.defaultUUID)
            }catch{
                debugPrint(error.localizedDescription)
            }
        }
        return true
    }
    

    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        Defaults[.deviceToken] = token
        
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
        let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        
        return sceneConfiguration
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
        // 由于Sqlit 底层通知延迟，手动更新
        Task.detached(priority: .background) {
            await  MessagesManager.shared.updateGroup()
        }
        
        if notification.request.content.interruptionLevel.rawValue > 1{
            completionHandler(.banner)
        }else{
            completionHandler(.badge)
            Haptic.impact(.light)
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
        
        if let id:String = userInfo.raw(.id), let group = DatabaseManager.shared.delete(id) {
            UNUserNotificationCenter.current()
                .removeDeliveredNotifications(withIdentifiers: [group])
        }
        
        AppManager.shared.registerForRemoteNotifications()
        
        completionHandler(.newData)
    }
    
    
}

extension AppDelegate:  PTChannelManagerDelegate, PTChannelRestorationDelegate{
    
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        
        Queue.mainQueue().async{
            AppManager.shared.router = [.pushtalk]
        }
        
        PTTManager.setActive(true)
        
        if let activeChannel = Defaults[.pttHisChannel].first(where: {$0.isActive}){
            Task.detached(priority: .userInitiated){
                await self.pttManager.JoinOrLeval(channel: activeChannel, api: .join)
            }
        }
        
        
        return PTChannelDescriptor(name: "Domogo", image: UIImage(named: "logo2"))
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, didJoinChannel channelUUID: UUID, reason: PTChannelJoinReason) {
        Log.info("didJoinChannel", channelUUID)
        PTTManager.setActive(true)
        
    }
    
    func channelManager(_ channelManager: PTChannelManager, didLeaveChannel channelUUID: UUID, reason: PTChannelLeaveReason) {
        Log.info("didLeaveChannel", channelUUID)
        
        channelManager.leaveChannel(channelUUID: self.pttManager.defaultUUID)
        PTTManager.setActive(false)
        Defaults[.pttHisChannel].setActive()
        
    }
    
    func channelManager(_ channelManager: PTChannelManager, failedToJoinChannel channelUUID: UUID, error: any Error) {
        let error = error as NSError
        print(error)
        switch error.code{
        case PTChannelError.channelLimitReached.rawValue:
            break
        default:
            break
        }
        PTTManager.setActive(false)
        
        Toast.error(title: "服务被其他APP占用!")
    }
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didBeginTransmittingFrom source: PTChannelTransmitRequestSource) {
        Log.info("didBeginTransmittingFrom:", channelUUID.uuidString, source.rawValue)
        self.pttManager.setCategory(isPlay: false)
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didEndTransmittingFrom source: PTChannelTransmitRequestSource) {
        Log.info("didEndTransmittingFrom", source)

    }
    
    func channelManager(_ channelManager: PTChannelManager, receivedEphemeralPushToken pushToken: Data) {
        let token = pushToken.map { String(format: "%02.2hhx", $0) }.joined()
        Log.info("token:", token)
        Defaults[.pttToken] = token
        if let activeChannel = Defaults[.pttHisChannel].first(where: {$0.isActive}){
            Task.detached(priority: .userInitiated){
                await self.pttManager.JoinOrLeval(channel: activeChannel, api: .join)
            }
        }
    }
    
    func incomingPushResult(channelManager: PTChannelManager, channelUUID: UUID, pushPayload: [String : Any]) -> PTPushResult {
        
        guard let fileName = pushPayload["fileName"] as? String else {
            return .leaveChannel
        }
       
        Task.detached(priority: .userInitiated) {
            if let message = await self.pttManager.saveVoice(remoteFileName: fileName),
               let filePath = message.fileName(){
                try? await Task.sleep(for: .seconds(0.3))
                await self.pttManager.startPlaying(filePath: filePath)
            }else{
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    channelManager.setActiveRemoteParticipant(nil, channelUUID: self.pttManager.defaultUUID)
                }
            }
            
        }
        
        let activeSpeakerImage = UIImage(named: "logo2")
        let participant = PTParticipant(name: "新消息", image: activeSpeakerImage)
       
        return .activeRemoteParticipant(participant)
    }
//    AVAudioSessionCategorySoloAmbient
    
    func channelManager(_ channelManager: PTChannelManager, didActivate audioSession: AVAudioSession) {
        print("Did activate audio session", audioSession.mode,
              audioSession.category,
              audioSession.categoryOptions)
    
        
        if audioSession.category == .playAndRecord{
            self.pttManager.startRecording()
        }
        
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, didDeactivate audioSession: AVAudioSession) {
        print("Did deactivate audio session", audioSession.category)
 
        if audioSession.category == .playback{
            self.pttManager.stopPlaying(pause: false)
            return
        }
        self.pttManager.stopRecording()
    }
    
    
}
