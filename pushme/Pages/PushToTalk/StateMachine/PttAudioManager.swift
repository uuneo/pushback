//
//  PttAudioManager.swift
//  pushme
//
//  Created by lynn on 2025/8/15.
//

import Foundation
import Opus
import AVFAudio
import UIKit


@globalActor
actor PttAudioManager{
    static let shared = PttAudioManager()
    
    var state: TalkieState = .idle{
        didSet{
            PTTManager.setState(state)
        }
    }
    
    var hasMicrophonePermission: Bool = false{
        didSet{
            PTTManager.setHasMicrophonePermission(hasMicrophonePermission)
        }
    }
    
    
    // MARK: - 播放器
    let playerEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let EQ = AVAudioUnitEQ(numberOfBands: 2)
    var format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
    var waitPlayList: [URL] = []
    
    
    // MARK: - 录音
    let recordEngine = AVAudioEngine()
    var oggWriter = OggOpusWriter()
    var dataItem = DataItem()
    var audioBuffer = Data()
    
    private init(){
        Task{  await setupConnect() }
    }
    
    
    
    private func setCurrentData(currentTime: Double, micLevel: Float, elapsedTime: Double){
        
        PTTManager.setCurrentData(currentTime: currentTime, micLevel: micLevel, elapsedTime: elapsedTime)
    }
    

}

// MARK: - 播放器
extension PttAudioManager{
    
    private func setupConnect(){
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
    
    func setDB(_ value: Float){
        self.EQ.globalGain = value
    }
    
    
    func addList(_ value: URL){
        self.waitPlayList.append(value)
    }
    
    
    func startPlay(_ file: URL? = nil) async {
        
        if let file = file{
            self.addList(file)
        }
        
        if self.state != .idle || waitPlayList.count <= 0{
            return
        }
        
        guard waitPlayList.count > 0 else { return }
        
        
        self.state = .playing
        
        let filePath = waitPlayList.removeFirst()
        
        do{
            PTTManager.shared.setDisplayLink(isPaused: false)
            
           
            
            Self.setCategory()
            
            self.setupConnect()
            
            let audioFile = try AVAudioFile(forReading: filePath)
            
            playerNode.removeTap(onBus: 0)
            playerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, when in
     
                let micLevel = Self.calculateLevelPercentage(from: buffer)
                
                var currentTime: Double {
                    
                    if let nodeTime = self.playerNode.lastRenderTime,
                       let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) {
                        let seconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                        return seconds
                    }
                    return 0
                }
                
                self.setCurrentData(currentTime: currentTime, micLevel: micLevel, elapsedTime: 0)
            }
            
            
            try playerEngine.start()
            
            playerNode.play()
            
            _ = await playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
            
            guard self.state == .playing else {
                if self.playerEngine.isRunning{
                    self.stopPlay()
                }
                
                return
            }
            
            while self.waitPlayList.count > 0 {
                
                guard self.state == .playing else {
                    if self.playerEngine.isRunning{
                        self.stopPlay()
                    }
                    return
                }
                
                let file = self.waitPlayList.removeFirst()
                
                let audioFile = try AVAudioFile(forReading: file)
                
                _ = await  playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
            }
            
            if self.playerEngine.isRunning{
                self.stopPlay()
            }
            self.state = .idle
        }catch{
            
            if self.playerEngine.isRunning{
                self.stopPlay()
            }
            Log.error("播放数据：",error.localizedDescription)
        }
    }
    
    
    func stopPlay() {
        PTTManager.shared.setDisplayLink(isPaused: true)
        self.playerEngine.stop()
        self.playerEngine.reset()
        
        self.playerNode.stop()
        self.playerNode.removeTap(onBus: 0)
        self.playerNode.reset()
        
        
        PTTManager.shared.setActiveRemoteParticipant()
        
        
        self.setCurrentData(currentTime: 0, micLevel: 0, elapsedTime: 0)
        print("播放结束")
        self.state = .idle
        
    }
    
}

// MARK: - 录音
extension PttAudioManager{
    
    func startRecord(){
        
        if !hasMicrophonePermission{
            self.requestMicrophonePermission()
        }
        
        switch state{
        case .playing: self.stopPlay()
        case .recording: return
        case .idle: break
        }
        
        self.state = .recording
        
        PTTManager.shared.setDisplayLink(isPaused: false)
        
        do {
            
            
            Self.setCategory(true, .playAndRecord, mode: .default)
            
            self.setupRecordEngine()
            
            try recordEngine.start()
            Log.info("🎤 开始录音（AGC 已启用）")
            
        } catch {
            Log.error(error.localizedDescription)
            Toast.error(title: "音频引擎启动失败")
        }
        
    }
    
    func stopRecord(_ clear: Bool = false) -> Data? {
        PTTManager.shared.setDisplayLink(isPaused: true)
        
        self.recordEngine.inputNode.removeTap(onBus: 0)
        self.recordEngine.stop()
        
        self.state = .idle
        
        self.oggWriter.writeFrame(nil, frameByteCount: 0)
        
        self.setCurrentData(currentTime: 0, micLevel: 0, elapsedTime: 0)
        
        if clear{
            self.oggWriter = OggOpusWriter()
            self.dataItem = DataItem()
            return nil
        }
        guard self.oggWriter.encodedDuration() > 0.2  else {  return nil }
        
        let data = self.dataItem.data()
        
        if !clear{
            self.oggWriter = OggOpusWriter()
            self.dataItem = DataItem()
        }
        
        if waitPlayList.count > 0{
            Task{
                await self.startPlay()
            }
        }
        
        return data
    }
    
    
    func setupRecordEngine( ){
        
        Self.setCategory(true, .playAndRecord, mode: .default)
        
        
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
            
            let mic = Self.calculateLevelPercentage( from: buffer)
            self.setCurrentData(currentTime: 0, micLevel: mic, elapsedTime: elapsedTime)
        }
        
        recordEngine.prepare()
    }
    
    
    
    private func processAndDisposeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        
        guard let bufferData = Self.conversionFloat32ToInt16Buffer(buffer) else { return }
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
    
}

extension PttAudioManager {
    
    static func setCategory(_ active: Bool = true,
                            _ category: AVAudioSession.Category = .playback,
                            mode: AVAudioSession.Mode = .default){
        
        let session = AVAudioSession.sharedInstance()
        
        do{
            if active{
                try session.setCategory(category,
                                        mode: mode,
                                        options: [.allowBluetooth,
                                                  .interruptSpokenAudioAndMixWithOthers,
                                                  .allowBluetoothA2DP
                                        ] )
            }
            
            
            
            try session.setActive(active, options: .notifyOthersOnDeactivation)
            try session.overrideOutputAudioPort(.speaker)
            
            if let inputs = AVAudioSession.sharedInstance().availableInputs {
                if let bluetooth = inputs.first(where: { $0.portType == .bluetoothHFP }) {
                    try AVAudioSession.sharedInstance().setPreferredInput(bluetooth)
                }
            }
        }catch{
            Log.error("设置setActive失败：",error.localizedDescription)
        }
    }
    
    static func conversionFloat32ToInt16Buffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
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
    
    static func calculateLevelPercentage(from buffer: AVAudioPCMBuffer) -> Float {
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
        let meterLevel = Self.scaledPower(power: avgPower)
        
        return Float(Int(meterLevel * 100))
        
    }
    
    
    static func scaledPower(power: Float) -> Float {
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
    
    
    
    
    static func getFileUrl( name: String, folderName:String = "PTT") -> URL? {
        
        let fileManager = FileManager.default
        
        do {
            // 获取应用的 Documents 目录
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            // 创建文件夹的路径
            let folderURL = documentsDirectory.appendingPathComponent(folderName)
            
            // 检查文件夹是否存在，如果不存在则创建
            if !fileManager.fileExists(atPath: folderURL.path) {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("Folder created at: \(folderURL.path)")
            }
            
            // 创建文件的保存路径
            let fileURL = folderURL.appendingPathComponent(name)
            return fileURL
        }catch{
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    
    private func requestMicrophonePermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            self.hasMicrophonePermission = granted
        }
    }
    
}
