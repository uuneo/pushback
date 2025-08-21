//
//  PttPlayer.swift
//  pushme
//
//  Created by lynn on 2025/8/21.
//

import AVKit
import Defaults

class PttPlayer{
    
    static let shared = PttPlayer()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let EQ = AVAudioUnitEQ(numberOfBands: 2)
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
    private var callback:((Double, Double, Double) -> Void)? = nil
    
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
        
        engine.attach(playerNode)
        engine.attach(EQ)
        engine.connect(playerNode, to:  self.EQ, format: format)
        engine.connect( self.EQ, to:  engine.mainMixerNode, format: format)
    }
    
    func setCallback(response: @escaping (Double, Double, Double) -> Void){
        self.callback = response
    }
    
    func play(filePath: URL)  async throws {
        
        let audioFile = try AVAudioFile(forReading: filePath)
        
        playerNode.removeTap(onBus: 0)
        playerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, when in
 
            let micLevel = self.calculateLevelPercentage(from: buffer)
            
            var currentTime: Double {
                
                if let nodeTime = self.playerNode.lastRenderTime,
                   let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) {
                    let seconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                    return seconds
                }
                return 0
            }
            
            self.callback?(currentTime, micLevel, 0)
        }
        
        
        try engine.start()
        
        playerNode.play()
        
        _ = await playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
        
        
        
        
        self.stop()
    }
    
    func stop(){
        self.playerNode.removeTap(onBus: 0)
        self.playerNode.stop()
        self.engine.stop()
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
