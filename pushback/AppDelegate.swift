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
import CrashReporter
import AppIntents




class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate{


	let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)

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

		if Defaults[.deviceToken] != token{

			Defaults[.deviceToken] = token
			// MARK: 注册设备
			Task.detached {
				await PushbackManager.shared.registers()
			}
		}


	}

	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		// MARK:  处理注册失败的情况
		Log.debug(error)
	}


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

#if !DEBUG
		let config = PLCrashReporterConfig(signalHandlerType: .mach, symbolicationStrategy: [])
		if let crashReporter = PLCrashReporter(configuration: config) {
			// Enable the Crash Reporter.
			do {
				try crashReporter.enableAndReturnError()
			} catch {
				print("Warning: Could not enable crash reporter: \(error)")
			}

			if crashReporter.hasPendingCrashReport() {
				do {
					let data = try crashReporter.loadPendingCrashReportDataAndReturnError()

					// Retrieving crash reporter data.
					let report = try PLCrashReport(data: data)

					if let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
						PushbackManager.shared.fullPage = .crash(text)
					} else {
						print("CrashReporter: can't convert report to text")
					}
				} catch {
					print("CrashReporter failed to load and parse with error: \(error)")
				}

				// Purge the report.
				crashReporter.purgePendingCrashReport()
				return true
			}
		} else {
			print("Could not create an instance of PLCrashReporter")
		}
#endif
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
                                   actions: [copyAction, muteAction],
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
        
        PushbackManager.shared.page = .message
        PushbackManager.shared.messagePath = []
        DispatchQueue.main.async{
            PushbackManager.shared.selectId = content.userInfo[Params.messageId.name] as? String
            PushbackManager.shared.selectGroup = content.threadIdentifier
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


		notificatonHandler(userInfo: notification.request.content.userInfo)


		if self.getLevel(userInfo:  notification.request.content.userInfo) > 2{
			completionHandler(.banner)
		}else{
			completionHandler(.badge)
		}
	}

	func notificatonHandler(userInfo: [AnyHashable : Any]){
		if let urlStr = userInfo["url"] as? String, let url = URL(string: urlStr) {
			PushbackManager.openUrl(url: url)
		}
	}


	func getLevel(userInfo: [AnyHashable : Any]) -> Int {
		// 获取用户信息中的 level 值
		if let level = userInfo["level"] as? String {
			// 尝试将 level1 转换为整数
			if let levelNumber = Int(level), (0...10).contains(levelNumber) {
				return levelNumber
			}

			// 使用 switch 语句判断不同的字符串值
			switch level.lowercased() {
				case "passive":
					return 0
				case "active":
					return 1
				case "timeSensitive":
					return 2
				case "critical":
					return 3
				default:
					return 1
			}
		}
		return 1 // 如果没有 level 信息，则返回默认值 1
	}

}


class QuickActionSceneDelegate:UIResponder,UIWindowSceneDelegate{
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		QuickAction.selectAction = shortcutItem
	}
}
