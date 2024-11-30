//
//  CallHandler.swift
//  NotificationServiceExtension
//
//  Created by He Cho on 2024/8/8.
//

import AudioToolbox
import Foundation
import AVFoundation

class CallHandler: NotificationContentHandler {
	/// 循环播放的铃声
	var soundID: SystemSoundID = 0
	/// 播放完毕后，返回的 content
	var content: UNMutableNotificationContent? = nil
	
	var identifier: String? = nil
	
	func handler(identifier: String, content bestAttemptContent: UNMutableNotificationContent) async throws -> UNMutableNotificationContent {
		
		let userInfo = bestAttemptContent.userInfo
		
		guard userInfo[Params.call.name] as? String == "1" || userInfo["mode"] as? String == "1"  else {
			return bestAttemptContent
		}
		self.content = bestAttemptContent
		self.identifier = identifier
		
		self.registerObserver()
		self.sendLocalNotification()
		
		// 远程推送在响铃结束后静默不显示
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
	private func sendLocalNotification() {
		// 推送id和推送的内容都使用远程APNS的
		guard let selfContent = self.content,
			  let identifier = self.identifier,
			  let content = selfContent.mutableCopy() as? UNMutableNotificationContent else {
			return
		}
		if !content.isCritical { // 重要警告的声音可以无视静音模式，所以别把这特性给弄没了
			content.sound = nil
		}
		let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
		UNUserNotificationCenter.current().add(request)
	}
	
	
	// 开始播放铃声，startAudioWork(completion:) 方法的异步包装
	private func startAudioWork() async {
		await withCheckedContinuation { continuation in
			var hasResumed = false

			// Start the audio work, and provide a completion handler
			self.startAudioWork {
				// Check if the continuation has already been resumed
				if !hasResumed {
					continuation.resume()
					hasResumed = true
				}
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
		
		
		let soundName: String
		let soundType: String
		
		if let sound = ((content.userInfo[Params.aps.name] as? [String: Any])?[Params.sound.name] as? String)?.split(separator: "."),
		   let name = sound.first, let ext = sound.last{
			debugPrint(type(of: name),type(of: ext))
			soundName = String(name)
			soundType = String(ext)
		}else{
			soundName = "oldphone"
			soundType = Params.caf.name
		}
		
		
		debugPrint(soundName, soundType)
		// 先找自定义上传的铃声，再找内置铃声
		guard let audioPath = getSoundInCustomSoundsDirectory(soundName: "\(soundName).\(soundType)") ??
			Bundle.main.path(forResource: soundName, ofType: soundType)
				
		else {
			completion()
			return
		}
		
		let startDate = Date()
		let soundFile = mergeCAFFilesToDuration(inputFile: URL(string: audioPath)!)
		let endDate = Date()
		let executionTime = endDate.timeIntervalSince(startDate)
		print("Execution Time: \(executionTime) seconds")
		
		// 创建响铃任务
		AudioServicesCreateSystemSoundID(soundFile as CFURL, &soundID)
		// 播放震动、响铃
		AudioServicesPlayAlertSound(soundID)
		// 监听响铃完成状态
		AudioServicesPlaySystemSoundWithCompletion(soundID) {
			AudioServicesDisposeSystemSoundID(self.soundID)
		}
		
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
		CFNotificationCenterAddObserver(notification, observer, { _, pointer, _, _, userInfoPointer in
			guard let observer = pointer else { return }
			let handler = Unmanaged<CallHandler>.fromOpaque(observer).takeUnretainedValue()
			
			if let identifier = handler.identifier{
				UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
			}
			
			handler.stopAudioWork()
			handler.startAudioWorkCompletion?()
			
		}, BaseConfig.kStopCallHandlerKey as CFString, nil, .deliverImmediately)
	}
	
	func getSoundInCustomSoundsDirectory(soundName: String) -> String? {
		// 扩展访问不到主APP中的铃声，需要先共享铃声文件，再实现自定义铃声响铃
		guard let soundsDirectoryUrl = BaseConfig.getSoundsGroupDirectory() else {
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
	
	func mergeCAFFilesToDuration(inputFile: URL, targetDuration: TimeInterval = 30, silenceDuration: TimeInterval = 0.3) -> URL {
		
		// 输出文件路径
		guard let outputFile = BaseConfig.getSoundsGroupDirectory()?.appendingPathComponent("call-\(inputFile.lastPathComponent)") else { return inputFile}
		
		if FileManager.default.fileExists(atPath: outputFile.path){
			return outputFile
		}
		
		do {
			// 打开输入文件并获取音频格式
			let audioFile = try AVAudioFile(forReading: inputFile)
			let audioFormat = audioFile.processingFormat
			let sampleRate = audioFormat.sampleRate
			let channelCount = Int(audioFormat.channelCount)
			
			// 计算空帧和目标帧数
			let silenceFrames = AVAudioFramePosition(silenceDuration * sampleRate)
			let targetFrames = AVAudioFramePosition((targetDuration - silenceDuration) * sampleRate)
			var currentFrames: AVAudioFramePosition = 0
			
			// 创建输出音频文件
			let outputAudioFile = try AVAudioFile(forWriting: outputFile, settings: audioFormat.settings)
			
			// 添加自定义时长的空帧
			let silenceBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(silenceFrames))!
			for channel in 0..<channelCount {
				let silencePointer = silenceBuffer.floatChannelData![channel]
				memset(silencePointer, 0, Int(silenceFrames) * MemoryLayout<Float>.size) // 填充零值
			}
			silenceBuffer.frameLength = AVAudioFrameCount(silenceFrames)
			try outputAudioFile.write(from: silenceBuffer)
			
			// 循环读取文件数据，拼接到剩余目标时长
			while currentFrames < targetFrames {
				// 每次读取整个文件的音频数据
				let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
				if let buffer = buffer {
					try audioFile.read(into: buffer)
					
					// 计算剩余所需帧数
					let remainingFrames = targetFrames - currentFrames
					if AVAudioFramePosition(buffer.frameLength) > remainingFrames {
						// 如果当前缓冲区帧数超出所需，截取剩余部分
						let truncatedBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(remainingFrames))!
						for channel in 0..<channelCount {
							let sourcePointer = buffer.floatChannelData![channel]
							let destinationPointer = truncatedBuffer.floatChannelData![channel]
							memcpy(destinationPointer, sourcePointer, Int(remainingFrames) * MemoryLayout<Float>.size)
						}
						truncatedBuffer.frameLength = AVAudioFrameCount(remainingFrames)
						try outputAudioFile.write(from: truncatedBuffer)
						break
					} else {
						// 否则写入整个缓冲区
						try outputAudioFile.write(from: buffer)
						currentFrames += AVAudioFramePosition(buffer.frameLength)
					}
				}
				// 重置输入文件读取位置
				audioFile.framePosition = 0
			}
			
			print("CAF file processed and extended successfully to \(targetDuration) seconds at \(outputFile.path).")
			
		} catch {
			print("Error processing CAF file: \(error)")
		}
		
		
		
		return outputFile
	}
}


