//
// PttAudioManager.swift
//  pushme
//
//  Created by lynn on 2025/8/21.
//

import AVKit
import Defaults
import Opus

@globalActor
actor PttAudioManager{
    
    static let shared = PttAudioManager()
    
    // MARK: - 播放器
    private let playerEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let EQ = AVAudioUnitEQ(numberOfBands: 2)
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
   
    
    
    // MARK: - 录音
    private let recordEngine = AVAudioEngine()
    private var oggWriter = OggOpusWriter()
    private var dataItem = DataItem()
    private var audioBuffer = Data()
    
    // MARK: - other
    private var callback:((Double, Double, Double) -> Void)? = nil
    private var soundID: SystemSoundID = 0
    
    private init(){
        // Band 1: 提升人声清晰度（2kHz）
        let band1 = EQ.bands[0]
        band1.filterType = .parametric
        band1.frequency = 2000
        band1.bandwidth = 1.5
        band1.gain = 10.0
        band1.bypass = false
        
        // Band 2: - 减少低频杂音（低切）
        let band2 = EQ.bands[1]
        band2.filterType = .highPass
        band2.frequency = 100
        band2.bandwidth = 0.5
        band2.bypass = false
        EQ.globalGain = Float(Defaults[.pttVoiceVolume] * 15)
        
        playerEngine.attach(playerNode)
        playerEngine.attach(EQ)
        playerEngine.connect(playerNode, to:  self.EQ, format: format)
        playerEngine.connect( self.EQ, to:  playerEngine.mainMixerNode, format: format)
    }
    
    
    
    func setCallback(response: @escaping (Double, Double, Double) -> Void){
        self.callback = response
    }
    
    // MARK: - player
    
    func play(filePath: URL) async throws {
        
        guard !playerNode.isPlaying else{ return }
        
        let audioFile = try AVAudioFile(forReading: filePath)
        
        let asset = AVURLAsset(url: filePath)
        let duration = try await asset.load(.duration)
        
        playerEngine.mainMixerNode.removeTap(onBus: 0)
        playerEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, when in
           
            let micLevel = self.calculateLevelPercentage(from: buffer)
            
            var currentTime: Double {
                
                if let nodeTime = self.playerNode.lastRenderTime,
                   let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) {
                    let seconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                    return seconds
                }
                return 0
            }
            self.callback?(currentTime, micLevel, CMTimeGetSeconds(duration))
        }
        
        
        try playerEngine.start()
        
        playerNode.play()
        
        _ = await playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
        
        debugPrint("播放成功")
    }
    
    
    func stop() {
        debugPrint("🚦 stop() 进入")
        self.playerEngine.mainMixerNode.removeTap(onBus: 0)
        debugPrint("✅ removeTap 完成")
        self.playerNode.stop()
        debugPrint("🏁 stop() 完成")
        self.playerEngine.stop()
        debugPrint("✅ playerNode.stop 完成")
    }
    
    
    func setVolume(_ value: Float){
        self.EQ.globalGain =  value
    }
    
    // MARK: - 录音
    func record() throws{
        
        let input = recordEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        
        self.oggWriter = OggOpusWriter()
        self.dataItem = DataItem()
        self.oggWriter.inputSampleRate = Int32(format.sampleRate)
        self.oggWriter.begin(with: self.dataItem)
        
        input.engine?.stop()
        
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize:  1024, format: format) { buffer, when in
        
            
            let elapsedTime = self.oggWriter.encodedDuration()
            
            if elapsedTime > 60{ return }
            
            self.processAndDisposeAudioBuffer(buffer)
            
            let mic = self.calculateLevelPercentage( from: buffer)
            self.callback?(0, mic, elapsedTime)
        }
        
        try recordEngine.start()
        Log.info("🎤 开始录音（AGC 已启用）")
        
    }
    
    func end() -> Data?{
        
        self.recordEngine.inputNode.removeTap(onBus: 0)
        self.recordEngine.inputNode.reset()
        self.recordEngine.stop()
        self.oggWriter.writeFrame(nil, frameByteCount: 0)

        let data = self.dataItem.data()
        
        
        if self.oggWriter.encodedDuration() > 0.2  {
            
            self.oggWriter = OggOpusWriter()
            self.dataItem = DataItem()
            
            return data
        }
        
        self.oggWriter = OggOpusWriter()
        self.dataItem = DataItem()
        return nil
       
    }
    
    private func processAndDisposeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        
        guard let bufferData = self.conversionFloat32ToInt16Buffer(buffer) else { return }
        let buffer = bufferData.audioBufferList.pointee.mBuffers
        
        let sampleRate = 16000
        let frameDurationMs = 60
        let bytesPerSample = 2
        let encoderPacketSizeInBytes = sampleRate * frameDurationMs / 1000 * bytesPerSample
        
        
        let currentEncoderPacket = malloc(encoderPacketSizeInBytes)!
        defer { free(currentEncoderPacket) }
        
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
                
                self.oggWriter.writeFrame(currentEncoderPacket.assumingMemoryBound(to: UInt8.self), frameByteCount: UInt(currentEncoderPacketSize))
            }
        }
    }
    
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
        
        for index in 0..<Int(frameLength) {
            let floatSample = min(max(sourcePointer[index], -1.0), 1.0)
            destinationPointer[index] = Int16(clamping: Int(floatSample * 32767.0))
        }
        
        return convertedBuffer
    }
    
    // MARK: - OTHER
    
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
            // 重置播放状态
            self.soundID = 0
            complete?()
        }
        
    }
    
    // MARK: - OTHER
    
    func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else {
            return 0.0
        }
        
        let channelDataValue = channelData.pointee
        // 4
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride)
            .map { channelDataValue[$0] }
        
        // 5
        let rms = sqrt(channelDataValueArray.map {
            return $0 * $0
        }
            .reduce(0, +) / Float(buffer.frameLength))
        
        // 6
        let avgPower = 20 * log10(rms)
        // 7
        let meterLevel = self.scaledPower(power: avgPower)
        
        return Double(Int(meterLevel * 100))
        
    }
    
    func scaledPower(power: Float) -> Float {
        // 1. 避免 NaN 或 Inf
        guard power.isFinite else {
            return 0.0
        }
        
        // 参考的最小分贝值（静音阈值）
        let minDb: Float = -80.0
        
        // 2. 小于阈值直接当作静音
        if power < minDb {
            return 0.0
        }
        
        // 3. 如果超过 1.0（非常大声），直接归一化到 1.0
        if power >= 1.0 {
            return 1.0
        }
        
        // 4. 按比例线性映射到 0~1
        return (abs(minDb) - abs(power)) / abs(minDb)
    }
    
}


enum TipsSound: String{
    case pttconnect
    case pttnotifyend
    case cbegin
    case bottle
    case qrcode
}
