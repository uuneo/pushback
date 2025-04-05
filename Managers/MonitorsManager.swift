//
//  Monitors.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import Foundation
import Network
import UserNotifications
import SwiftUI

class MonitorsManager: ObservableObject {
    // 单例模式，确保只有一个监控器实例
    static let shared = MonitorsManager()
    
    private var monitor: NWPathMonitor  // 网络状态监控器
    private let queue = DispatchQueue.global(qos: .background)  // 异步队列用于监听网络变化
    
    // 网络连接状态
    @Published var isConnected: Bool = false
    
    // 推送通知授权状态
    @Published var isAuthorized: Bool = false
    
    private init() {
        monitor = NWPathMonitor()  // 初始化监控器
        
        // 设置网络路径更新的处理器
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // 判断当前网络是否可用
                self.isConnected = path.status == .satisfied
                
                // 如果网络连接正常，则检查推送通知权限
                if self.isConnected {
                    self.checkNotificationAuthorization()
                }
            }
        }
        
        // 开始监听网络状态变化
        monitor.start(queue: queue)
        
        // 检查通知授权状态
        checkNotificationAuthorization()
        
        // 监听应用程序从后台变为前台的事件，检查通知授权
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkNotificationAuthorization),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        // 取消网络监控器
        monitor.cancel()
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    // 检查推送通知授权状态
    @objc func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorizationStatus = settings.authorizationStatus == .authorized
            
            // 如果授权状态发生变化，则更新状态
            if self.isAuthorized != authorizationStatus {
                DispatchQueue.main.async {
                    self.isAuthorized = authorizationStatus
                    // 如果授权，注册推送通知
                    if self.isAuthorized {
                        self.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    // MARK: 注册设备以接收远程推送通知
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { (granted, _) in
            if granted {
                // 如果授权，注册设备接收推送通知
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
#if DEBUG
                // 如果没有授权推送通知，打印调试信息
                Log.debug("没有打开推送")
#endif
            }
        }
    }
}
