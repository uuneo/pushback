//
//  CallHandler.swift
//  NotificationService
//  Changed by uuneo 2024/8/8.
//

import AudioToolbox
import Foundation

class CallHandler: NotificationContentHandler {
	/// 循环播放的铃声
	var soundID: SystemSoundID = 0
	/// 播放完毕后，返回的 content
	var content: UNMutableNotificationContent? = nil
	/// 是否需要停止播放，由主APP发出停止通知赋值
	var needsStop = false
	
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let userInfo = bestAttemptContent.userInfo
		
		guard userInfo[Params.call.name] as? String == "1" || userInfo[Params.mode.name] as? String == "1"  else {
			return bestAttemptContent
		}
		self.content = bestAttemptContent
		self.registerObserver()
		self.sendLocalNotification(identifier: identifier, content: bestAttemptContent)
		self.content?.interruptionLevel = .passive
		await startAudioWork()
		return bestAttemptContent
	}
	
	func serviceExtensionTimeWillExpire(contentHandler: (UNNotificationContent) -> Void) {
		stopAudioWork()
		if let content {
			contentHandler(content)
		}
	}
	
	/// 生成一个本地推送
	private func sendLocalNotification(identifier: String, content: UNMutableNotificationContent) {
		// 推送id和推送的内容都使用远程APNS的
		guard let content = content.mutableCopy() as? UNMutableNotificationContent else {
			return
		}
		if content.getLevel() > 2 { // 重要警告的声音可以无视静音模式，所以别把这特性给弄没了
			content.sound = nil
		}
		let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
		UNUserNotificationCenter.current().add(request)
	}

	// 开始播放铃声，startAudioWork(completion:) 方法的异步包装
	private func startAudioWork() async {
		return await withCheckedContinuation { continuation in
			self.startAudioWork {
				continuation.resume()
			}
		}
	}

	/// 铃声播放结束时的回调
	var startAudioWorkCompletion: (() -> Void)? = nil
	/// 播放铃声
	private func startAudioWork(completion: @escaping () -> Void) {
		guard let content else {
			completion()
			return
		}
		self.startAudioWorkCompletion = completion
		
		let sound = ((content.userInfo[Params.aps.name] as? [String: Any])?[Params.sound.name] as? String)?.split(separator: ".")
		let soundName: String
		let soundType: String
		if sound?.count == 2, let first = sound?.first, let last = sound?.last {
			soundName = String(first)
			soundType = String(last)
		} else {
			soundName = "oldphone"
			soundType = Params.caf.name
		}
		
		// 先找自定义上传的铃声，再找内置铃声
		guard let audioPath = getSoundInCustomSoundsDirectory(soundName: "\(soundName).\(soundType)") ??
			Bundle.main.path(forResource: soundName, ofType: soundType)
		else {
			completion()
			return
		}
		
		let fileUrl = URL(string: audioPath)
		// 创建响铃任务
		AudioServicesCreateSystemSoundID(fileUrl! as CFURL, &soundID)
		// 播放震动、响铃
		AudioServicesPlayAlertSound(soundID)
		// 监听响铃完成状态
		let selfPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
		AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { sound, clientData in
			guard let pointer = clientData else { return }
			let processor = unsafeBitCast(pointer, to: CallHandler.self)
			if processor.needsStop {
				processor.startAudioWorkCompletion?()
				return
			}
			// 音频文件一次播放完成，再次播放
			AudioServicesPlayAlertSound(sound)
		}, selfPointer)
	}

	/// 停止播放
	private func stopAudioWork() {
		AudioServicesRemoveSystemSoundCompletion(soundID)
		AudioServicesDisposeSystemSoundID(soundID)
	}
	
	/// 注册停止通知
	func registerObserver() {
		let notification = CFNotificationCenterGetDarwinNotifyCenter()
		let observer = Unmanaged.passUnretained(self).toOpaque()
		CFNotificationCenterAddObserver(notification, observer, { _, pointer, _, _, _ in
			guard let observer = pointer else { return }
			let processor = Unmanaged<CallHandler>.fromOpaque(observer).takeUnretainedValue()
			processor.needsStop = true
		}, BaseConfig.kStopCallHandlerKey as CFString, nil, .deliverImmediately)
	}
	
	func getSoundInCustomSoundsDirectory(soundName: String) -> String? {
		// 扩展访问不到主APP中的铃声，需要先共享铃声文件，再实现自定义铃声响铃
		guard let soundsDirectoryUrl = BaseConfig.getSoundslibraryDirectory() else {
			return nil
		}
		let path = soundsDirectoryUrl.appendingPathComponent(soundName).path
		if FileManager.default.fileExists(atPath: path) {
			return path
		}
		return nil
	}

	deinit {
		let observer = Unmanaged.passUnretained(self).toOpaque()
		let name = CFNotificationName(BaseConfig.kStopCallHandlerKey as CFString)
		CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), observer, name, nil)
	}
	
}


