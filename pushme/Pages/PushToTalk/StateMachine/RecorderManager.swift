//
//  Recorder.swift
//  pushme
//
//  Created by lynn on 2025/8/9.
//

import Foundation
import Opus
import AVFAudio


class RecorderManager {
    
    static let shared = RecorderManager()
    
    
    private init(){
        self.oggWriter = OggOpusWriter()
        self.dataItem = DataItem()
    }
    
    private var audioEngine:AVAudioEngine? = nil
    private var oggWriter: OggOpusWriter
    private var dataItem: DataItem
    private var audioBuffer = Data()
    
    
    func startEngine() {
        do {
            self.setPlayAndRecord()
            if audioEngine == nil{
                _ = self.setupEngine()
            }
            guard let audioEngine = self.audioEngine else{ throw "no init audioEngine" }
            try audioEngine.start()
            Log.info("🎤 开始录音（AGC 已启用）")
            
        } catch {
            Log.error(error.localizedDescription)
            Toast.error(title: "音频引擎启动失败")
        }
        
    }
    
    func stopEngine(_ clear: Bool = false) -> Data? {
        
        self.audioEngine?.inputNode.removeTap(onBus: 0)
        self.audioEngine?.stop()
        self.audioEngine?.reset()
      
        self.audioEngine = nil
        self.oggWriter.writeFrame(nil, frameByteCount: 0)
        PTTManager.setCurrentData(currentTime: 0, micLevel: 0, elapsedTime: 0)
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
        
        return data
    }
    
    
    func setupEngine( ) -> Bool{
        
        self.setPlayAndRecord()
        
        self.audioEngine = AVAudioEngine()
        
        guard let audioEngine = self.audioEngine else{ return false}
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        
        self.oggWriter = OggOpusWriter()
        self.dataItem = DataItem()
        self.oggWriter.inputSampleRate = Int32(format.sampleRate)
        self.oggWriter.begin(with: self.dataItem)
        
        input.installTap(onBus: 0, bufferSize:  1024, format: format) {[weak self] buffer, when in
            guard let self = self else { return }
            let elapsedTime = self.oggWriter.encodedDuration()
            
            if elapsedTime > 60{ return }
            
            self.processAndDisposeAudioBuffer(buffer)
            
            let mic = ToolBox.calculateLevelPercentage( from: buffer)
            PTTManager.setCurrentData(currentTime: 0, micLevel: mic, elapsedTime: elapsedTime)
        }
        
        audioEngine.prepare()
        return true
    }
    
    
    
    func setPlayAndRecord(){
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(.playAndRecord,
                                    mode: .default,
                                    options:  [.allowBluetooth, .defaultToSpeaker]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)

        }catch{
            Log.error("session:",error.localizedDescription)
        }
        
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
}


enum ToolBox{
    
    
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
    
}
