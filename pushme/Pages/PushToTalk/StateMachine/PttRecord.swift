//
//  PttRecord.swift
//  pushme
//
//  Created by lynn on 2025/8/21.
//
import Foundation
import AVKit
import Opus

class PttRecord{
    
    static let shared = PttRecord()
    // MARK: - 录音
    private let recordEngine = AVAudioEngine()
    private var oggWriter = OggOpusWriter()
    private var dataItem = DataItem()
    private var audioBuffer = Data()
    private var callback:((Double, Double, Double) -> Void)? = nil
    
    private init(){}
    
    func setCallback(response: @escaping (Double, Double, Double) -> Void){
        self.callback = response
    }
    
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

        guard self.oggWriter.encodedDuration() > 0.2  else {  return nil }

        return self.dataItem.data()
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
