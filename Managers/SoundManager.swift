//
//  SoundManager.swift
//  pushback
//
//  Created by He Cho on 2024/11/18.
//

import AVFoundation

class SoundManager{
	 static func mergeCAFFilesToDuration(inputFile: URL, outputFile: URL, targetDuration: TimeInterval = 30) {
		do {
			// 打开输入文件并获取音频格式
			let audioFile = try AVAudioFile(forReading: inputFile)
			let audioFormat = audioFile.processingFormat
			let sampleRate = audioFormat.sampleRate
			let fileDuration = Double(audioFile.length) / sampleRate
			
			// 计算目标帧数
			let targetFrames = AVAudioFramePosition(targetDuration * sampleRate)
			var currentFrames: AVAudioFramePosition = 0
			
			// 创建输出音频文件
			let outputAudioFile = try AVAudioFile(forWriting: outputFile, settings: audioFormat.settings)
			
			// 循环读取文件数据，拼接到目标时长
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
						let channelCount = Int(buffer.format.channelCount)
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
	}

}



