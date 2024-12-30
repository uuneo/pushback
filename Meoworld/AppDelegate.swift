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
import CrashReporter

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
		debugPrint(error)
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

		// 必须在应用一开始就配置，否则应用可能提前在配置之前试用了 Realm() ，则会创建两个独立数据库。
		setupRealm()


		UNUserNotificationCenter.current().delegate = self


		let copyAction =  UNNotificationAction(identifier:Identifiers.copyAction, title: String(localized: "复制后关闭"), options: [.destructive],icon: .init(systemImageName: "doc.on.doc"))


		let detailActionAction =  UNNotificationAction(identifier:Identifiers.detailAction, title: String(localized: "查看详情"), options: [.foreground, ],icon: .init(systemImageName: "ellipsis.circle"))

		// 创建 category
		UNUserNotificationCenter.current().setNotificationCategories([
			UNNotificationCategory(identifier: Identifiers.reminderCategory,
								   actions: [copyAction, detailActionAction],
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

		let userInfo = response.notification.request.content.userInfo

		notificatonHandler(userInfo: userInfo)
		// MARK: 点击信息 跳转到信息页面
		NotificationCenter.default.post(name: .messagePreview, object: nil)



		completionHandler()
	}



	// 处理应用程序在前台是否显示通知
	func userNotificationCenter(_ center: UNUserNotificationCenter,
								willPresent notification: UNNotification,
								withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {


		notificatonHandler(userInfo: notification.request.content.userInfo)

		HapticsManager.shared.complexSuccess()

		if self.getLevel(userInfo:  notification.request.content.userInfo) > 2{
			completionHandler(.banner)
		}else{
			completionHandler(.badge)
		}
	}

	func notificatonHandler(userInfo: [AnyHashable : Any]){

		if userInfo["call"] as? String == "1"{
			BaseConfig.stopCallNotificationHandler(mode: "click")
		}

		if let urlStr = userInfo["url"] as? String,
		   let url = URL(string: urlStr)
		{
			PushbackManager.shared.openUrl(url: url)
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

