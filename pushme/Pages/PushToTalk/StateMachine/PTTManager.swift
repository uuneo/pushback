//
//  PTTManager.swift
//  pushme
//
//  Created by lynn on 2025/8/9.
//

import Foundation
import AVFAudio
import UIKit
import Defaults

import PushToTalk




class PTTManager: NetworkManager, ObservableObject{
    
    static let shared = PTTManager()

    private let database = DatabaseManager.shared
    private let audioManager = PttAudioManager.shared
    
    var channelManager:PTChannelManager?
    
    let defaultUUID = UUID(uuidString: "2F2A187B-A8E9-1F3A-92F9-212B57199105")!

    
    @Published private(set) var micLevel: Float = .zero
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var currentTime: Double = 0
    
    @Published private(set) var state:TalkieState = .idle
    @Published private(set) var hasMicrophonePermission:Bool  = false
    @Published private(set) var active: Bool = false
    @Published private(set) var channelUsers:Int = 0
    
    private var timer: Timer?
    private let interval: TimeInterval = 20
    private var throttler = Throttler(delay: 0.02)
   
    private override init() {
        super.init()
        PTChannelManager.channelManager(delegate: self, restorationDelegate: self){ manager, err in
            guard err == nil else { return }
            self.channelManager = manager
        }
        Task.detached(priority: .userInitiated) {
            await self.audioManager.setCallback(response: self.setCurrentData)
        }
       
    }

    private(set) var playArr:[PttPlayInfo] = []
    
    func startTransmitting(){
        
        channelManager?.requestBeginTransmitting(channelUUID: defaultUUID)
    }
    func stopTransmitting(){
        self.stopRecording()
        channelManager?.stopTransmitting(channelUUID: defaultUUID)
    }
    

    func addPlayList(_ value: PttPlayInfo){
        self.playArr.append(value)
    }
    
    func setDB( _ value: Float){
        Task.detached(priority: .userInitiated) {
            await self.audioManager.setVolume(Float(value) * 15)
        }
    }
    
    
    func stopRecording(_ canale:Bool = false) {
        Task.detached(priority: .userInitiated) {
            if let data = await self.audioManager.end(){
              
                if !canale {
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
                
                if self.playArr.count > 0 {
                    Self.setState(.playing)
                    await self._playNext()
                }
                
                
            }
        }
    }
    
    
    private func _playNext() async {
        guard playArr.count > 0 && self.state == .playing else {
            
            self.stopPlaying()
            
            return
        }
        let info = playArr.removeFirst()
        self.setActiveRemoteParticipant(.init(name: info.name, image: info.avatar))
        
        do{
            try await self.audioManager.play(filePath: info.file)
            await self._playNext()
        }catch{
            self.stopPlaying() 
            debugPrint( "播放失败：",error.localizedDescription)
        }
    }
    
    
    func stopPlaying() {
        Task.detached(priority: .userInitiated) {
          
            await self.audioManager.stop()
            self.setActiveRemoteParticipant()
            Self.setState(.idle)
            debugPrint("正常播放结束")
        }
    }
    
    func setActiveRemoteParticipant(_ participant: PTParticipant? = nil){
        self.channelManager?.setActiveRemoteParticipant(participant, channelUUID: self.defaultUUID)
    }
    

    
    func JoinChannel(_ channel: PTTChannel){
        guard let channelManager else {
            Toast.error(title: "初始化失败")
            return
        }
        let channelDescriptor = PTChannelDescriptor(name: "独蘑菇频道", image: UIImage(named: "logo"))
        
        channelManager.requestJoinChannel(channelUUID: defaultUUID, descriptor: channelDescriptor)
        
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
    
    func playTips(_ name: TipsSound, complete: @escaping () -> Void){
        Task.detached(priority: .userInitiated) {
            await self.audioManager.playTips(name) {
                complete()
            }
        }
    }
    
}

extension PTTManager{
    
    func setCurrentData(_ currentTime: Double, _ micLevel: Double, _  elapsedTime: Double){
        throttler.throttle {
            DispatchQueue.main.async {
                self.currentTime = currentTime
                self.micLevel = Float(micLevel)
                self.elapsedTime = elapsedTime
            }
        }
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
    
    func setCategory(_ active: Bool = true,
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
    
    func getFileUrl( name: String, folderName:String = "PTT") -> URL? {
        
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
    
    
    func requestMicrophonePermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            self.hasMicrophonePermission = granted
        }
    }
}

extension PTTManager: PTChannelManagerDelegate, PTChannelRestorationDelegate{
   
    
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        
        Queue.mainQueue().async{
            AppManager.shared.router = [.pushtalk]
        }
        
        PTTManager.setActive(true)
        
        if let activeChannel = Defaults[.pttHisChannel].first(where: {$0.isActive}){
            Task.detached(priority: .userInitiated){
                await self.JoinOrLeval(channel: activeChannel, api: .join)
            }
        }
        
        
        return PTChannelDescriptor(name: "Domogo", image: UIImage(named: "logo2"))
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, didJoinChannel channelUUID: UUID, reason: PTChannelJoinReason) {
        Log.info("didJoinChannel", channelUUID)
        PTTManager.setActive(true)
        channelManager.setTransmissionMode(.fullDuplex, channelUUID: defaultUUID)
    }
    
    func channelManager(_ channelManager: PTChannelManager, didLeaveChannel channelUUID: UUID, reason: PTChannelLeaveReason) {
        Log.info("didLeaveChannel", channelUUID)

        PTTManager.setActive(false)
        Defaults[.pttHisChannel].setActive()
        
    }
    
    func channelManager(_ channelManager: PTChannelManager, failedToJoinChannel channelUUID: UUID, error: any Error) {
        let error = error as NSError
        print(error)
        switch error.code{
        case PTChannelError.channelLimitReached.rawValue:
            break
        default:
            break
        }
        PTTManager.setActive(false)
        
        Toast.error(title: "服务被其他APP占用!")
    }
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didBeginTransmittingFrom source: PTChannelTransmitRequestSource) {
        Log.info("didBeginTransmittingFrom:", channelUUID.uuidString, source.rawValue)
        if state == .playing{
            self.stopPlaying()
        }
        Self.setState(.recording)
        
        self.setCategory(true, .playAndRecord, mode: .default)
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didEndTransmittingFrom source: PTChannelTransmitRequestSource) {
        Log.info("didEndTransmittingFrom", source)
        Self.setState(.idle)
    }
    
    func channelManager(_ channelManager: PTChannelManager, receivedEphemeralPushToken pushToken: Data) {
        let token = pushToken.map { String(format: "%02.2hhx", $0) }.joined()
        Log.info("token:", token)
        Defaults[.pttToken] = token
        if let activeChannel = Defaults[.pttHisChannel].first(where: {$0.isActive}){
            Task.detached(priority: .userInitiated){
                await self.JoinOrLeval(channel: activeChannel, api: .join)
            }
        }
    }
    
    func incomingPushResult(channelManager: PTChannelManager, channelUUID: UUID, pushPayload: [String : Any]) -> PTPushResult {
        
        guard let fileName = pushPayload["fileName"] as? String else {
            return .leaveChannel
        }
        let defaultUUID = self.defaultUUID
        Task.detached(priority: .userInitiated) { 
            if let message = await self.saveVoice(remoteFileName: fileName),
               let filePath = message.fileName(){
                try? await Task.sleep(for: .seconds(0.3))
            
                await MainActor.run {
                    self.playArr.append(PttPlayInfo(name: "新消息", image: "logo2", file: filePath))
                }
                if self.state == .idle {
                    Self.setState(.playing)
                    self.setCategory(true, .playAndRecord)
                    await self._playNext()
                }
               
            }else{
                try? await Task.sleep(for: .seconds(0.3))
                try? await channelManager.setActiveRemoteParticipant(nil, channelUUID: defaultUUID)
            }
            
        }
        
        let activeSpeakerImage = UIImage(named: "logo2")
        let participant = PTParticipant(name: "新消息", image: activeSpeakerImage)
       
        return .activeRemoteParticipant(participant)
    }
    
    func channelManager(_ channelManager: PTChannelManager, didActivate audioSession: AVAudioSession) {
        print("Did activate audio session", audioSession.mode,
              audioSession.category,
              audioSession.categoryOptions)
        
        if state == .recording{
            Task.detached(priority: .userInitiated) {
                try await self.audioManager.record()
            }
            
        }
        
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, didDeactivate audioSession: AVAudioSession) {
        print("Did deactivate audio session", audioSession.category)
       
    }
    
    
}
