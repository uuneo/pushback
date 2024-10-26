//
//  Monitors.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import Foundation
import Network
import UserNotifications
import SwiftUI

class Monitors: ObservableObject {
    static let shared = Monitors()
    
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .background)
    
    // wifi
    @Published var isConnected: Bool = true
    
    // notification
    @Published var isAuthorized: Bool = true
    
    init() {
      
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
			guard let self else { return }
			
			DispatchQueue.main.async{
				self.isConnected = path.status == .satisfied
				if(self.isConnected ){
					self.checkNetworkConnect()
				}
			}
			
        }
        monitor.start(queue: queue)
        
        checkNotificationAuthorization()
        
        // 添加监听器来检测设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkNotificationAuthorization),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        monitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func checkNetworkConnect(){
        self.registerForRemoteNotifications()
    }
    
    
    
    @objc func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            let authorizationStatus = settings.authorizationStatus == .authorized
            
            if self.isAuthorized != authorizationStatus{
				DispatchQueue.main.async{
					self.isAuthorized = authorizationStatus
					if self.isAuthorized{
						self.registerForRemoteNotifications()
					}
				}
            }
            
        }
    }
    
    // MARK: 注册设备
    func registerForRemoteNotifications() {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .carPlay], completionHandler: { (_ granted: Bool, _: Error?) -> Void in
            
            if granted {
				DispatchQueue.main.async{
					UIApplication.shared.registerForRemoteNotifications()
				}
            }
            else {
#if DEBUG
                debugPrint("没有打开推送")
#endif
            }
        })
    }
      

}
