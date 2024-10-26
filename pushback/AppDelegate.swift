//
//  AppDelegate.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//

import Foundation
import UIKit
import PushKit
import SwiftyJSON
import Defaults
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate{
	
	
	let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
	
	func setupRealm() {
		// Tell Realm to use this new configuration object for the default Realm
		Realm.Configuration.defaultConfiguration = kRealmDefaultConfiguration
		
#if DEBUG
		let realm = try? Realm()
		debugPrint("message count: \(realm?.objects(Message.self).count ?? 0)")
#endif
	}
	
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		
		
		let deviceTokenDisk = Defaults[.deviceToken]
		
		if deviceTokenDisk != token{
			
			Defaults[.deviceToken] = token
			// MARK: 注册设备
			PushBackManager.shared.registers()
		}
		
		
	}
	

	
	
	
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		// MARK:  处理注册失败的情况
#if DEBUG
		debugPrint(error)
#endif
		
	}
	
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		
		// 必须在应用一开始就配置，否则应用可能提前在配置之前试用了 Realm() ，则会创建两个独立数据库。
		setupRealm()
		
		
		UNUserNotificationCenter.current().delegate = self
		
		
		let copyAction =  UNNotificationAction(identifier:Identifiers.copyAction, title: String(localized: "复制后关闭"), options: [.destructive],icon: .init(systemImageName: "doc.on.doc"))
		
		
		let detailActionAction =  UNNotificationAction(identifier:Identifiers.detailAction, title: String(localized: "查看详情"), options: [.foreground],icon: .init(systemImageName: "ellipsis.circle"))
		
		// 创建 category
		let category = UNNotificationCategory(identifier: Identifiers.reminderCategory,
											  actions: [copyAction, detailActionAction],
											  intentIdentifiers: [],
											  options: [.hiddenPreviewsShowTitle])
		
		UNUserNotificationCenter.current().setNotificationCategories([category])
		
	
		
		
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
		
		notificatonHandler(userInfo: response.notification.request.content.userInfo)
		// MARK: 点击信息 跳转到信息页面
		NotificationCenter.default.post(name: .messagePreview, object: nil)
		debugPrint("点击了信息")
		completionHandler()
	}
	
	
	// 处理应用程序在前台是否显示通知
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		
		
		notificatonHandler(userInfo: notification.request.content.userInfo)
		
		HapticsManager.shared.complexSuccess()
		
		completionHandler(.badge)
		
	}
	
	func notificatonHandler(userInfo: [AnyHashable : Any]){
		if let urlStr = userInfo["url"] as? String,
		   let url = URL(string: urlStr)
		{
			PushBackManager.shared.openUrl(url: url, unOpen: nil)
		}
	}
	
	
	
	
}


class QuickActionSceneDelegate:UIResponder,UIWindowSceneDelegate{
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		QuickAction.selectAction = shortcutItem
	}
}

