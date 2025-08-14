//
//  PlayerManager.swift
//  pushme
//
//  Created by lynn on 2025/8/9.
//

import Foundation
import AVFAudio



// MARK: - 示例播放类
class PlayerManager {
    static let shared = PlayerManager()
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let EQ = AVAudioUnitEQ(numberOfBands: 2)
    
    private var waitPlayList: [URL] = []
    
    private var currentFile: URL?
    private var currentTime: TimeInterval = 0
    
    private var playState:PlayState = .idle
    
    private var format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
    
    private init(){ self.setupConnect()}
    
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
        
        audioEngine.attach(playerNode)
        audioEngine.attach(EQ)
        audioEngine.connect(playerNode, to:  self.EQ, format: format)
        audioEngine.connect( self.EQ, to:  audioEngine.mainMixerNode, format: format)
    }
    
    func setDB(_ value: Float){
        self.EQ.globalGain = value
    }
    
    enum PlayState{
        case playing
        case pause
        case idle
    }
    
    func addList(_ value: URL){
        self.waitPlayList.append(value)
    }
    
    func setPlayback(){
        
        let session = AVAudioSession.sharedInstance()
        
        do{
            
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: [.allowBluetooth, .interruptSpokenAudioAndMixWithOthers] )
            
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }catch{
            Log.error("设置setActive失败：",error.localizedDescription)
        }
    }
    
 
    
    func play(_ file: URL? = nil) async {
        
        var filePath: URL
        self.setPlayback()
        
        switch self.playState {
        case .playing:
            if let file = file{
                self.waitPlayList.append(file)
            }
            return
        case .pause:
            
            if let file = self.currentFile{
                filePath = file
            }else{
                if let file = file{
                    filePath = file
                }else if self.waitPlayList.count > 0{
                    filePath = self.waitPlayList.removeFirst()
                }else{
                    self.playState = .idle
                    return
                }
            }
            
            self.playState = .playing
        case .idle:
            if let file = file{
                filePath = file
            }else if waitPlayList.count > 0{
                filePath = waitPlayList.removeFirst()
            }else{
                return
            }
            self.playState = .playing
        }
    
        self.currentFile = filePath
        
        do{
            
            
            
            let audioFile = try AVAudioFile(forReading: filePath)
            
    
            playerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, when in
                guard let self = self else { return }
                let micLevel = ToolBox.calculateLevelPercentage(from: buffer)
                
                var currentTime: Double {
                    
                    if let nodeTime = playerNode.lastRenderTime,
                       let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
                        let seconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                        return seconds
                    }
                    return 0
                }
                
                self.currentTime = currentTime
                
                if PTTManager.shared.state == .playing{
                    PTTManager.setCurrentData(currentTime: currentTime, micLevel: micLevel, elapsedTime: 0)
                }else{
                    PTTManager.setCurrentData(currentTime: 0, micLevel: 0, elapsedTime: 0)
                }
            }
           
            audioEngine.prepare()
            
            try audioEngine.start()
           
            playerNode.play()
          
            _ = await playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
           
            guard self.playState == .playing else { throw "playState != .playing" }
           
            while self.waitPlayList.count > 0 {
                self.currentTime = 0
               
                guard self.playState == .playing else { throw "playState != .playing" }
                
                let file = self.waitPlayList.removeFirst()
                
                self.currentFile = file
                let audioFile = try AVAudioFile(forReading: file)
               
                _ = await  playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack)
            }
           
           
            self.stop(pause: false)
            
        }catch{
           
            self.stop(pause: false)
            Log.error("播放数据：",error.localizedDescription)
        }
    }

    
    func stop(pause: Bool) {
        
        self.playerNode.stop()
        self.playerNode.removeTap(onBus: 0)
        self.playerNode.reset()
        
        self.audioEngine.stop()
        self.audioEngine.reset()
        
        self.setupConnect()
        
        if !pause{
            self.currentFile = nil
            self.playState = .idle
        }else{
            self.playState = .pause
        }
        self.currentTime = 0
        PTTManager.shared.setActiveRemoteParticipant()
        PTTManager.setState(.idle)
        
        PTTManager.setCurrentData(currentTime: 0, micLevel: 0, elapsedTime: 0)
        print("播放结束5")
    }
    
 
}

