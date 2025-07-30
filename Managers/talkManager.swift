//
//  talkManager.swift
//  pushme
//
//  Created by lynn on 2025/7/19.
//

import Foundation
import PushToTalk
import AVFAudio
import UIKit
import Accelerate
import SwiftUI
import OpusBinding


class talkManager: NSObject, ObservableObject {
   
        
    
    static let shared = talkManager()
   
    var channelManager:PTChannelManager?
    
    var audioEngine = AVAudioEngine()
    var audioPlayer = AVAudioPlayer()
    
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var micLevel: Float = .zero
    @Published var active: Bool = false
    @Published var talkType:TalkType = .space
    
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("recorded.ogg")
    
    private  let throttler = Throttler(delay: 0.1)
    
    
    private var compressedWaveformSamples = Data()
    private var currentPeak: Int64 = 0
    private var currentPeakCount: Int = 0
    private var peakCompressionFactor: Int = 1
    private var micLevelPeak: Int16 = 0
    private var micLevelPeakCount: Int = 0
    
    private var oggWriter: OggOpusWriter = OggOpusWriter()
    private var dataItem: DataItem = DataItem()
    private var audioBuffer = Data()
    private var resumeData: Data?
    
    let defaultUUID = UUID(uuidString: "2F2A187B-A8E9-1F3A-92F9-212B57199105")!
    
    var hasMicrophonePermission = false
    
    private let queue = Queue(name: "PushTalkWrite", qos: .userInitiated)
    
    private var soundID: SystemSoundID = 0
    
    private var stoped:Bool = false
    
    private override init() {
        super.init()
        self.requestMicrophonePermission()
        self.prepareEngine()
    }
    
    


    func prepareEngine(_ inside: Bool = true) {
        
        if inside{
            Queue.mainQueue().async {
                self.micLevel = 0
            }
        }
        
        self.oggWriter = OggOpusWriter()
        self.dataItem = DataItem()
        self.oggWriter.begin(with: self.dataItem)
        self.audioEngine = AVAudioEngine()
        let input = self.audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        
        if input.numberOfInputs > 0{
            input.removeTap(onBus: 0)
        }
     
        input.installTap(onBus: 0, bufferSize:  1024, format: format) {[weak self] buffer, when in
            guard let self = self else { return }
            if let copiedBuffer = self.normalizeAndSave(buffer: buffer) {
                self.processAndDisposeAudioBuffer(copiedBuffer)
            }
            
            
            if inside{
                let elapsedTime = self.oggWriter.encodedDuration()
                Queue.mainQueue().async {
                    self.elapsedTime = elapsedTime
                }
            }
        }
        self.audioEngine.prepare()
    }
    
    func setCategoryForPlayAndRecord(c category: AVAudioSession.Category = .playAndRecord, m mode: AVAudioSession.Mode = .default){
        let session = AVAudioSession.sharedInstance()
        if session.category != .playAndRecord{
            do{
                try session.setCategory(category,
                                        mode: mode,
                                        options: [.allowBluetooth, .defaultToSpeaker,  .mixWithOthers])
                try session.setActive(true)
                
            }catch{
                debugPrint(error.localizedDescription)
            }
        }
        
    }
    
    
    
    func OutStopAudioEngine(){
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        do{
            try self.stopAndSave(outAudioUrl: self.fileURL)
        }catch{
            debugPrint(error.localizedDescription)
        }
    }
    
    func startAudioEngine() {
        
        self.queue.async {
            self.setCategoryForPlayAndRecord()
            Queue.mainQueue().async {
                self.talkType = .ready
            }

            do {
                try self.audioEngine.start()
                print("🎤 开始录音（AGC 已启用）")
                Queue.mainQueue().async {
                    self.talkType = .listen
                }
            } catch {
                print("❌ 启动失败: \(error)")
                Queue.mainQueue().async {
                    self.talkType = .close
                }
            }
        }
    }

    func stopEngine(complete: (()-> Void )? = nil){
        self.queue.async {
            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            do{
                try self.stopAndSave(outAudioUrl: self.fileURL)
            }catch{
                debugPrint(error.localizedDescription)
            }
            
            Queue.mainQueue().async {
                self.elapsedTime = 0
                self.micLevel = .zero
                self.talkType = .space
            }
            complete?()
        }
        
        
    }
    
    func joinChannel() {
        
        guard let channelManager else { return }
        
        if let active = channelManager.activeChannelUUID{
            channelManager.leaveChannel(channelUUID: active)
            return
        }
        
        let channelDescriptor = PTChannelDescriptor(name: "频道监听中...", image: UIImage(named: "logo2"))
        // Ensure that your channel descriptor and UUID are persisted to disk for later use.
        
        channelManager.requestJoinChannel(channelUUID: defaultUUID, descriptor: channelDescriptor)
        
        channelManager.setTransmissionMode(.fullDuplex, channelUUID: defaultUUID)
        
        
    }
    enum TipsSound: String{
        case pttconnect
        case pttnotifyend
        case cbegin
        case da
        case bottle
        case so
        case qrcode
    }
    
    
    func playTips(_ fileName: TipsSound, fileExtension:String = "aac", complete:(()->Void)? = nil) {
        
        guard let url = Bundle.main.url(forResource: fileName.rawValue, withExtension: fileExtension) else { return }
        // 先释放之前的 SystemSoundID（如果有），避免内存泄漏或重复播放
        AudioServicesDisposeSystemSoundID(self.soundID)
        
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback{
            do {
                // 配置为播放模式
                try session.setCategory(.playback, mode: .default, options: [])
                
                try session.setActive(true)
                
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
        
        AudioServicesCreateSystemSoundID(url as CFURL, &self.soundID)
        // 播放音频，播放完成后执行回调
        AudioServicesPlaySystemSoundWithCompletion(self.soundID) {
            // 释放资源
            AudioServicesDisposeSystemSoundID(self.soundID)
            DispatchQueue.main.async {
                // 重置播放状态
                self.soundID = 0
                complete?()
            }
        }
        
    }
    
    
    
    func transmitting(begin: Bool){
        guard let channelManager else { return }
        if begin{
            channelManager.requestBeginTransmitting(channelUUID: defaultUUID)
            
        }else{
            channelManager.stopTransmitting(channelUUID: defaultUUID)
            
        }
        
    }
    
    
    func playVoice(){
        
        let session = AVAudioSession.sharedInstance()
        
        do{
            
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            let data = try Data(contentsOf: self.fileURL)
            
            self.audioPlayer = try AVAudioPlayer(data: data)
            self.audioPlayer.play()
            self.audioPlayer.volume = 0.7
        }catch{
            debugPrint(error.localizedDescription)
        }
    }
    
    
    private func requestMicrophonePermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.hasMicrophonePermission = granted
            }
        }
    }
    
    func stopAndSave(outAudioUrl:URL) throws {
        guard self.oggWriter.encodedDuration() > 0  else {
            return
        }
        let state = self.oggWriter.pause()
        if let stateDict = state as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: stateDict, options: [])
                self.resumeData = jsonData
            } catch {
                Log.error("ManagedAudioRecorder", "Failed to JSON: \(error)")
            }
        }
        
        try? FileManager.default.removeItem(at: outAudioUrl)
        guard  let data = self.dataItem.data() else { throw "没有数据" }
        try data.write(to: URL(fileURLWithPath: outAudioUrl.path()))

        
    }
    
    func process(_ buffer: AVAudioPCMBuffer) {
        let millisecondsPerPacket = 60
        let bytesPerSample = 2 // Int16
        let encoderPacketSizeInBytes = 16000 / 1000 * millisecondsPerPacket * bytesPerSample
        let frameLength = Int(buffer.frameLength)
        
        guard let floatChannelData = buffer.floatChannelData?[0] else {
            print("Error: No channel data")
            return
        }
        
        let floatSamples = floatChannelData
        let floatSampleCount = frameLength
        
        // Step 1: 准备 Float -> Int16 的中间缓冲区
        let scaledFloatBuffer = UnsafeMutablePointer<Float>.allocate(capacity: floatSampleCount)
        let int16Buffer = UnsafeMutablePointer<Int16>.allocate(capacity: floatSampleCount)
        defer {
            scaledFloatBuffer.deallocate()
            int16Buffer.deallocate()
        }
        
        var gain: Float = 32767.0
        vDSP_vsmul(floatSamples, 1, &gain, scaledFloatBuffer, 1, vDSP_Length(floatSampleCount))
        
        for i in 0..<floatSampleCount {
            let sample = scaledFloatBuffer[i]
            int16Buffer[i] = Int16(clamping: Int(sample.rounded()))
        }
        
        // Step 2: 构造帧并逐个传入
        // 把这段数据传给 encoder
        let int16MutableBytes = UnsafeMutableRawPointer(int16Buffer).assumingMemoryBound(to: UInt8.self)
        var offset = 0
        while offset < floatSampleCount * bytesPerSample {
            let remainingBytes = floatSampleCount * bytesPerSample - offset
            let packetSize = min(encoderPacketSizeInBytes, remainingBytes)
            
            oggWriter.writeFrame(int16MutableBytes.advanced(by: offset), frameByteCount: UInt(packetSize))
            
            offset += packetSize
        }
    }
    
    func processAndDisposeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let bufferData = conversionFloat32ToInt16Buffer(buffer) else { return }
        let buffer = bufferData.audioBufferList.pointee.mBuffers
        
        let millisecondsPerPacket = 60
        let encoderPacketSizeInBytes = 16000 / 1000 * millisecondsPerPacket * 2
        
        let currentEncoderPacket = malloc(encoderPacketSizeInBytes)!
        defer {
            free(currentEncoderPacket)
        }
        
        var bufferOffset = 0
        
        while true {
            var currentEncoderPacketSize = 0
            
            while currentEncoderPacketSize < encoderPacketSizeInBytes {
                if self.audioBuffer.count != 0 {
                    let takenBytes = min(self.audioBuffer.count, encoderPacketSizeInBytes - currentEncoderPacketSize)
                    if takenBytes != 0 {
                        self.audioBuffer.withUnsafeBytes { rawBytes -> Void in
                            let bytes = rawBytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                            
                            memcpy(currentEncoderPacket.advanced(by: currentEncoderPacketSize), bytes, takenBytes)
                        }
                        self.audioBuffer.replaceSubrange(0 ..< takenBytes, with: Data())
                        currentEncoderPacketSize += takenBytes
                    }
                } else if bufferOffset < Int(buffer.mDataByteSize) {
                    let takenBytes = min(Int(buffer.mDataByteSize) - bufferOffset, encoderPacketSizeInBytes - currentEncoderPacketSize)
                    if takenBytes != 0 {
                        memcpy(currentEncoderPacket.advanced(by: currentEncoderPacketSize), buffer.mData?.advanced(by: bufferOffset), takenBytes)
                        
                        bufferOffset += takenBytes
                        currentEncoderPacketSize += takenBytes
                    }
                } else {
                    break
                }
            }
            
            if currentEncoderPacketSize < encoderPacketSizeInBytes {
                self.audioBuffer.append(currentEncoderPacket.assumingMemoryBound(to: UInt8.self), count: currentEncoderPacketSize)
                break
            } else {
                self.processWaveformPreview(samples: currentEncoderPacket.assumingMemoryBound(to: Int16.self), count: currentEncoderPacketSize / 2)
                
                self.oggWriter.writeFrame(currentEncoderPacket.assumingMemoryBound(to: UInt8.self), frameByteCount: UInt(currentEncoderPacketSize))
            }
        }
    }
    
    func processWaveformPreview(samples: UnsafePointer<Int16>, count: Int) {
        for i in 0 ..< count {
            var sample = samples.advanced(by: i).pointee
            if sample < 0 {
                if sample == Int16.min {
                    sample = Int16.max
                } else {
                    sample = -sample
                }
            }
            
            self.currentPeak = max(Int64(sample), self.currentPeak)
            self.currentPeakCount += 1
            if self.currentPeakCount == self.peakCompressionFactor {
                var compressedPeak = self.currentPeak
                withUnsafeBytes(of: &compressedPeak, { buffer in
                    self.compressedWaveformSamples.append(buffer.bindMemory(to: UInt8.self))
                })
                self.currentPeak = 0
                self.currentPeakCount = 0
                
                let compressedSampleCount = self.compressedWaveformSamples.count / 2
                if compressedSampleCount == 200 {
                    self.compressedWaveformSamples.withUnsafeMutableBytes { rawCompressedSamples -> Void in
                        let compressedSamples = rawCompressedSamples.baseAddress!.assumingMemoryBound(to: Int16.self)
                        
                        for i in 0 ..< 100 {
                            let maxSample = Int64(max(compressedSamples[i * 2 + 0], compressedSamples[i * 2 + 1]))
                            compressedSamples[i] = Int16(maxSample)
                        }
                    }
                    self.compressedWaveformSamples.count = 100 * 2
                    self.peakCompressionFactor *= 2
                }
            }
            
            if self.micLevelPeak < sample {
                self.micLevelPeak = sample
            }
            self.micLevelPeakCount += 1
            
            if self.micLevelPeakCount >= 1200 {
                let level = Float(self.micLevelPeak) / 4000.0
                throttler.throttle {
                    Queue.mainQueue().async {
                        self.micLevel = level
                        self.micLevelPeak = 0
                        self.micLevelPeakCount = 0
                    }
                }
            }
        }
    }
    
    
}
extension talkManager{
    func conversionFloat32ToInt16Buffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: buffer.format.sampleRate,
                                         channels: buffer.format.channelCount,
                                         interleaved: true) else {
            return nil
        }
        
        let frameLength = buffer.frameLength
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
            return nil
        }
        convertedBuffer.frameLength = frameLength
        
        // 获取输入 float32 样本指针
        guard let sourcePointer = buffer.floatChannelData?[0] else {
            return nil
        }
        
        // 获取目标 int16 样本指针
        guard let destinationPointer = convertedBuffer.int16ChannelData?[0] else {
            return nil
        }
        
        for i in 0..<Int(frameLength) {
            let floatSample = min(max(sourcePointer[i], -1.0), 1.0)
            destinationPointer[i] = Int16(clamping: Int(floatSample * 32767.0))
        }
        
        return convertedBuffer
    }
    
    // 深拷贝 PCM buffer，避免缓冲区复用导致数据混乱
    func copyPCMBuffer(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: buffer.format.commonFormat,
                                         sampleRate: buffer.format.sampleRate,
                                         channels: buffer.format.channelCount,
                                         interleaved: buffer.format.isInterleaved) else {
            return nil
        }
        guard let copiedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else {
            return nil
        }
        copiedBuffer.frameLength = buffer.frameLength
        
        for channel in 0..<Int(buffer.format.channelCount) {
            if let src = buffer.floatChannelData?[channel], let dst = copiedBuffer.floatChannelData?[channel] {
                memcpy(dst, src, Int(buffer.frameLength) * MemoryLayout<Float>.size)
            }
        }
        return copiedBuffer
    }
    
    
    /// 对 PCMBuffer 第0通道做动态增益归一化，防止溢出剪辑，并深拷贝保存结果
    /// - 参数：
    ///   - buffer: 输入的 AVAudioPCMBuffer，内容会被修改
    ///   - desiredRMS: 目标 RMS 音量（0~1），默认0.3
    ///   - maxGain: 最大放大倍数，默认10，防止爆音
    func normalizeAndSave(buffer: AVAudioPCMBuffer, desiredRMS: Float = 0.3, maxGain: Float = 10.0) -> AVAudioPCMBuffer?{
        guard let channelData = buffer.floatChannelData?[0] else { return  nil}
        let frameLength = Int(buffer.frameLength)
        
        // 1. 计算 RMS
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // 2. 计算安全增益
        let gain = desiredRMS / max(rms, 0.0001)
        let safeGain = min(gain, maxGain)
        
        // 3. 应用增益并裁剪防止溢出
        for i in 0..<frameLength {
            let amplified = channelData[i] * safeGain
            channelData[i] = min(max(amplified, -1.0), 1.0)
        }
        
        // 4. 深拷贝保存结果
        return copyPCMBuffer(buffer: buffer)
    }
    
}
