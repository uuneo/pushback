//
//  PTTManager.swift
//  pushme
//
//  Created by lynn on 2025/8/9.
//
import Foundation
import AVFAudio
import PushToTalk
import UIKit
import Defaults



class PTTManager: NetworkManager, ObservableObject{
    
    static let shared = PTTManager()

    
    private let audioManager = PttAudioManager.shared
    private let database = DatabaseManager.shared
    
    var channelManager:PTChannelManager?
    private var displayLink: CADisplayLink?
    
    private var isInterrupted = false
    
    private var interruptionObserver: NSObjectProtocol?
    
    private var soundID: SystemSoundID = 0
    
    let defaultUUID = UUID(uuidString: "2F2A187B-A8E9-1F3A-92F9-212B57199105")!
    
    private var current_Time: TimeInterval = 0
    private var mic_Level: Float = .zero
    private var elapsed_Time: TimeInterval = 0
    
    @Published private(set) var micLevel: Float = .zero
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var currentTime: Double = 0
    
    @Published private(set) var state:TalkieState = .idle
    @Published private(set) var hasMicrophonePermission:Bool  = false
    @Published private(set) var active: Bool = false
    @Published private(set) var channelUsers:Int = 0
    
    
    private var timer: Timer?
    private let interval: TimeInterval = 20
    
   
    private override init() {
        super.init()
        self.registerForNotifications()
        self.setupDisplayLink()
    }
    
    deinit{
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    
    func setCategory(isPlay: Bool = false){
        
        if isPlay{
            PttAudioManager.setCategory()
        }else{
            PttAudioManager.setCategory(true, .playAndRecord, mode: .default)
        }
    }
    
    func setDB(_ value: Float){
        Task{
            await self.audioManager.setDB(value)
        }
        
    }

    func addPlayList(_ value: URL){
        Task{
            await self.audioManager.addList(value)
        }
    }
    
    func startRecording() {
        setDisplayLink(isPaused: false)
        Task{
            await self.audioManager.startRecord()
        }
    }
    
    
    func stopRecording(_ canale:Bool = false) {
        Task{
            
            if let data = await self.audioManager.stopRecord(canale){
                
                Task.detached(priority: .background){
                    if let message =  await self.saveVoice(data: data){
                        let success = await self.sendVoice(message: message)
                        try await self.database.dbPool.write { db in
                            var message = message
                            message.status = success ? .success : .sendError
                            try message.update(db)
                            
                        }
                        if success {
                            Toast.success(title: "发送成功")
                        }
                    }
                    await MainActor.run{
                        self.micLevel = 0
                    }
                }
            }
        }
    }
    
    
    func startPlaying(filePath: URL? = nil) {
        setDisplayLink(isPaused: false)
        Task{
            await self.audioManager.startPlay(filePath)
        }
    }
    
    func stopPlaying(pause: Bool) {
     
        Task{
            await self.audioManager.stopPlay()
        }
    }
    
    func setActiveRemoteParticipant(_ participant: PTParticipant? = nil){
        Task{
          try? await self.channelManager?.setActiveRemoteParticipant(participant, channelUUID: self.defaultUUID)
        }
    }
    

    
    func JoinChannel(_ channel: PTTChannel){
        guard let channelManager else {
            Toast.error(title: "初始化失败")
            return
        }
        let channelDescriptor = PTChannelDescriptor(name: "独蘑菇频道", image: UIImage(named: "logo"))
        
        channelManager.requestJoinChannel(channelUUID: defaultUUID, descriptor: channelDescriptor)
        
        channelManager.setTransmissionMode(.fullDuplex, channelUUID: defaultUUID)
        
        Task.detached(priority: .userInitiated) {
            let success = await self.JoinOrLeval(channel: channel, api: .join)
            if success {
                Toast.success(title: "加入成功")
                Defaults[.pttHisChannel].set(channel)
                Defaults[.pttHisChannel].setActive(channel)
            }else{
                Toast.error(title: "加入失败")
                try await Task.sleep(for: .seconds(0.3))
                self.channelManager?.leaveChannel(channelUUID: self.defaultUUID)
            }
            
            
            
        }
    }
    
    func LevalChannel(_ channel: PTTChannel){
        guard let channelManager else { Toast.error(title: "初始化失败")
            return
        }
        
        if let active = channelManager.activeChannelUUID{
            channelManager.leaveChannel(channelUUID: active)
            Task.detached(priority: .userInitiated) {
                
                let success = await self.JoinOrLeval(channel: channel, api: .leave)
                if success {  Toast.success(title: "远程频道关闭成功") }
                else{ Toast.error(title: "远程频道关闭失败") }
                
            }
            return
        }
        Defaults[.pttHisChannel].set(channel)
        Defaults[.pttHisChannel].setActive(channel)
        self.micLevel = 0
        self.elapsedTime = 0
        self.currentTime = 0
        Self.setChannelUsers(0)
    }
    
    private func setupDisplayLink() {
      displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
      displayLink?.add(to: .current, forMode: .default)
      displayLink?.isPaused = true
    }
    
    @objc private func updateDisplay() {
        self.currentTime = self.current_Time
        self.micLevel = self.mic_Level
        self.elapsedTime = self.elapsed_Time
    }
    
    func setDisplayLink(isPaused:Bool = true){
        self.displayLink?.isPaused = isPaused
    }
    
    
}

extension PTTManager{
    
    static func setCurrentData(currentTime: Double, micLevel: Float, elapsedTime: Double){
        Self.shared.current_Time = currentTime
        Self.shared.mic_Level = micLevel
        Self.shared.elapsed_Time = elapsedTime
    }
    
    static func setState(_ value: TalkieState){
        Task{ @MainActor in
            Self.shared.state = value
        }
    }
    
    static func setHasMicrophonePermission(_ value: Bool){
        Task{ @MainActor in
            Self.shared.hasMicrophonePermission = value
        }
    }
    
    static func setActive(_ value: Bool){
        Task{ @MainActor in
            Self.shared.active = value
        }
    }
    
    static func setChannelUsers(_ value: Int){
        Task{ @MainActor in
            Self.shared.channelUsers = value
        }
    }
    
}

extension PTTManager{
    
    func saveVoice(data: Data) async -> PttMessageModel? {
        let id = Defaults[.id]
        guard  let channel = Defaults[.pttHisChannel].first(where: {$0.isActive}),
               let filePath = channel.filePath(userID: id)
        else { return nil}
        
        do{
            try data.write(to: filePath)
            let voice = try await self.database.dbPool.write { db in
                let voice = PttMessageModel(channel: channel.hex(), from: id, file: filePath.lastPathComponent, status: .sending)
                try voice.save(db)
                return voice
            }
            return voice
        }catch{
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    func saveVoice(remoteFileName: String) async -> PttMessageModel? {
        
        guard let data = await self.getVoice(fileName: remoteFileName) else { return  nil}
        
        let names = remoteFileName.split(separator: "-").compactMap({String($0)})
        guard names.count == 5 else { return nil }
        let channel = names[0...2].joined(separator: "-")
        let id = names[4]
        
        guard let channel = Defaults[.pttHisChannel].first(where: {$0.hex() == channel}),
              let filePath = channel.filePath(userID: id) else { return  nil}
        
        do{
            try data.write(to: filePath)
            
            let voice = try await self.database.dbPool.write { db in
                let voice = PttMessageModel(channel: channel.hex(), from: id, file: filePath.lastPathComponent, status: .unread)
                try voice.save(db)
                return voice
            }
            return voice
        }catch{
            return nil
        }
    }
    
    
    
    private func registerForNotifications() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: nil
        )
        { [weak self] (notification) in
            guard let weakself = self else {
                return
            }
            
            let userInfo = notification.userInfo
            let interruptionTypeValue: UInt = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue)!
            
            switch interruptionType {
            case .began:
                weakself.isInterrupted = true
                Log.info("音频系统中断")
            case .ended:
                weakself.isInterrupted = false
                Log.info("音频系统恢复")
            @unknown default:
                break
            }
        }
    }
    
    
    
    enum TipsSound: String{
        case pttconnect
        case pttnotifyend
        case cbegin
        case bottle
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
    
}


extension PTTManager{
    enum API: String{
        case join = "/ptt/join"
        case leave = "/ptt/leave"
        case ping = "/ptt/ping"
        case send = "/ptt/send"
        case getVoice = "/ptt/voice"
    }
    
    func startPolling() {
        
        DispatchQueue.main.async {
            self.stopPolling()
            // 然后设置定时器
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
                Task.detached(priority: .background) {
                    await self?.ping()
                }
            }
        }
        
        
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func JoinOrLeval(channel: PTTChannel, api:API = .join) async -> Bool {
        let id = Defaults[.id]
        let token = Defaults[.pttToken]
        guard let server = channel.server else { return false }
        let url = server.url + api.rawValue
        
        do{
            Log.info("channel:", channel.hex())
            guard let result:baseResponse<Int> =  try await self.fetch(url: url, method: .post, params: [
                "id":id, "channel": channel.hex(), "token": token
            ], headers: [:], timeout: 3)else { return false}
            
            if let data = result.data{
                PTTManager.setChannelUsers(data)
                Log.info("频道人数:", data)
            }
            
            if api == .join{
                self.startPolling()
            }else{
                self.stopPolling()
            }
            
            
            return result.code == 0
        }catch{
            Log.error(error.localizedDescription)
            return false
        }
        
    }
    
    func ping() async {
        guard  let channel =  Defaults[.pttHisChannel].first(where: {$0.isActive}),
               let server = channel.server else { return }
        
        let url = server.url + API.ping.rawValue + "/\(channel.hex())"
        let token = Defaults[.pttToken]
        do{
            let data:baseResponse<Int> = try await self.fetch(url: url, method: .get, params: [:], headers: [ "X-Q": token ], timeout: 3)
            if let count = data.data{
                PTTManager.setChannelUsers(count)
            }
            try? await  PTTManager.shared.channelManager?.setServiceStatus(.ready, channelUUID: PTTManager.shared.defaultUUID)
        
            
        }catch{
            Log.error(error.localizedDescription)
            try? await PTTManager.shared.channelManager?.setServiceStatus(.connecting, channelUUID: PTTManager.shared.defaultUUID)
        }
        
    }
    
    func sendVoice(message: PttMessageModel) async  -> Bool{
        guard  let channel = Defaults[.pttHisChannel].first(where: {$0.isActive}),
               let server = channel.server,
               let filePath = BaseConfig.getPTTDirectory()?.appendingPathComponent(message.file)
        else { return false}
        let url =  server.url + API.send.rawValue
        
        
        
        do{
            let data = try Data(contentsOf: filePath)
            //                /// 加密
            //
            //                guard let data = CryptoModelConfig.data.encrypt(inputData: data) else {
            //                    throw "encrypt error"
            //                }
            
            let response = try await uploadFile(url: url,
                                                fileData: data,
                                                fileName:  message.file,
                                                mimeType: "audio/ogg")
            
            let result = try JSONDecoder().decode(String.self, from: response)
            Log.info(result)
            return result == "ok"
        }catch{
            Log.error(error.localizedDescription)
            return false
        }
    }
    
    func getVoice(fileName: String) async -> Data? {
        guard  let channel =  Defaults[.pttHisChannel].first(where: {$0.isActive}),
               let server = channel.server else { return nil }
        
        do{
            let url = server.url + API.getVoice.rawValue + "/\(fileName)"
            let data = try await self.fetch(url: url, method: .get, params: [:], headers: [:])
            //                /// 解密
            //                guard let data = CryptoModelConfig.data.decrypt(inputData: data) else { throw "decrypt error"}
            //
            return data
        }catch{
            Log.error(error.localizedDescription)
            return nil
        }
        
    }
}
