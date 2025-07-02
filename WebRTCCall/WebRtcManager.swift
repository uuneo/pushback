//
//  VoiceCallManager.swift
//  pushme
//
//  Created by lynn on 2025/6/16.
//

import Foundation
import WebRTC
import AVFoundation
import Foundation
import CryptoKit
import Starscream
import Defaults


class WebRtcManager: NSObject, LiveCommunicationDelegate {
    
    
    static let shared = WebRtcManager()
    
    private var liveCommunicationManager:CallerManager
    
    private var factory: RTCPeerConnectionFactory{
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
    }
    private var peerConnection: RTCPeerConnection?
    private var remoteAudioTrack: RTCAudioTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var pingTimer: Timer?
    private var socket: WebSocket!
    private let maxCount = 5
    private var connectionTimes = 0
    
    var signalConnected:Bool = false
    
    
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private let audioQueue = DispatchQueue(label: "audio")
    
    
    var localCallUser:CallUser
    var remoteCallUser:CallUser? = nil
    
    
    private override init() {
        self.localCallUser = Defaults[.user]
        if #available(iOS 17.4, *){
            self.liveCommunicationManager = LiveCommunicationManager()
        }else{
            self.liveCommunicationManager = CallBasicManager()
        }
        
        super.init()
        createSocket()
        configureAudioSession()
        liveCommunicationManager.delegate = self
    }
    
    
    
    
    private func createSocket() {
        
        var request = URLRequest(url: URL(string: "ws://192.168.1.5:8080?call=\(localCallUser.id)")!)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.socket.write(ping: "ping".data(using: .utf8)!){}
        }
    }
    
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }
    
    func setupPeerConnection( servers: [RTCIceServer]) {
        let config = RTCConfiguration()
        config.iceServers = servers
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        addAudioTrack()
    }
    
    func setupPeerConnection(id: String, token:String) async throws {
        guard let servers = await Self.fetchPrivateTurn(id: id, apiToken: token) else {
            throw "No Servers"
        }
        setupPeerConnection(servers: servers.default)
    }

    private func addAudioTrack() {
        guard let peerConnection else { return }
        
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        localAudioTrack = audioTrack
        peerConnection.add(audioTrack, streamIds: ["stream"])
    }
    
    

    func createOffer() async throws -> RTCSessionDescription {
        guard let peerConnection else { throw "No Init peerConnection" }
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
        
        let offer = try await peerConnection.offer(for: constraints)
        
        try await peerConnection.setLocalDescription(offer)

        return offer
    }
    
    func createAnswer() async throws -> RTCSessionDescription {
        guard let peerConnection else { throw "No Init peerConnection" }
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)

        let answer = try await peerConnection.answer(for: constraints)
        try await peerConnection.setLocalDescription(answer)
        return answer
    }


    func setRemoteSdp(sdp: String, type: RTCSdpType)async throws {
        guard let peerConnection else { throw "peerConnection No Init" }
        let desc = RTCSessionDescription(type: type, sdp: sdp)
        try await peerConnection.setRemoteDescription(desc)
        print("✅ Remote SDP set.")
    }
    
    func hangup() {
        self.endCall()
        guard let peerConnection else { return }
        peerConnection.close()
        self.peerConnection = nil
        DispatchQueue.main.async {
            AppManager.shared.fullPage = .none
        }
    }

    func addIceCandidate(_ candidate: RTCIceCandidate) {
        guard let peerConnection else { return }
        peerConnection.add(candidate){_ in}
        Log.info("添加IceCandidate")
    }
    
    // MARK: - 接听控制
    func answerCall(callUser: CallUser) async  {
        print("🔊 用户接听，开启远程音频播放")
        do{
            try await self.answer()
            let user = Defaults[.id]
            send(from: user, to: callUser.id, mode: .ready)
        }catch{
            Log.error(error.localizedDescription)
        }
    }
    
    func callerManagerJoinConversation(){
        guard let calluser = remoteCallUser else { return }
        Task.detached(priority: .userInitiated) {
            await self.answerCall(callUser: calluser)
        }
    }
    
    func callerManagerDidEndCall() {
        self.hangup()
    }
    
}



extension WebRtcManager: RTCPeerConnectionDelegate{
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        Log.info(stateChanged.description)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
      
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected:
            print("✅ ICE 连接成功，媒体可以传输了")
        case .completed:
            print("🎉 所有候选连接验证完成")
        case .failed, .disconnected:
            print("⚠️ ICE 连接失败或中断")
            self.endCall()
        case .closed:
            self.endCall()
        default:
            print("❌ 其他:", newState.description)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
        guard let user =  remoteCallUser else { return }
        let ice = IceCandidate(from: candidate)
        self.send(from: localCallUser.id, to: user.id, mode: .ice, ice: ice)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
}

extension WebRtcManager: WebSocketDelegate {
    func send(from: String, to: String, mode:SignalingMessage.Mode,
              sdp:String? = nil,ice:IceCandidate? = nil,
              turnId:String? = nil, turnToken:String? = nil) {
        guard let message = SignalingMessage(from: from, to: to, mode: mode, turnId: turnId, turnToken: turnToken, sdp: sdp,ice: ice).json() else {
            return
        }
        socket.write(string: message)
    }
    
    func SignalingProcessing(text: String) async throws{
        
        guard let data = text.data(using: .utf8),
               let data = try? JSONDecoder().decode(SignalingMessage.self, from: data) else {
            return
        }
        switch data.mode{
        case .answer:
            guard let sdp = data.sdp else { return }
            try await self.setRemoteSdp(sdp: sdp, type: .answer)
        case .offer:
            guard let sdp = data.sdp, let turnId = data.turnId, let token = data.turnToken else { return }
            try await self.setupPeerConnection(id: turnId, token: token)
            try await self.setRemoteSdp(sdp: sdp, type: .offer)
            let answer = try await self.createAnswer()
            self.send(from: data.to, to: data.from, mode: .answer, sdp: answer.sdp)
        case .ready:
            let offser = try await self.createOffer()
            self.send(from: data.to, to: data.from, mode: .offer, sdp: offser.sdp,
                      turnId: "43f96a3bb057238c2ef897cdac42b16b",
                      turnToken: "6b50e52b2198830b090ca3cd63576fd4803f71504534fab1ed985616d8df3d43")
        case .ice:
            guard let ice = data.ice else { return }
            self.addIceCandidate(ice.rtcIceCandidate)
        }
    }
    
    
    // MARK: - WebSocketDelegate
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            signalConnected = true
            print("WebSocket connected: \(headers)")
        case .disconnected(let reason, let code):
            signalConnected = false
            print("WebSocket disconnected: \(reason) (code: \(code))")
        case .text(let text):
//            print("Received text: \(text)")
            Task.detached(priority: .userInitiated) {
                do{
                    try await self.SignalingProcessing(text: text)
                }catch{
                    debugPrint(error.localizedDescription)
                }
            }
        case .binary(let data):
            print("Received data: \(data.count) bytes")
        case .error(let error):
            signalConnected = false
            print("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            if connectionTimes < maxCount{
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(connectionTimes) * 0.2){
                    self.connectionTimes += 1
                    self.socket.connect()
                }
            }
        case .ping(_), .pong(_):
            print("收到心跳包")
        case .viabilityChanged(_), .reconnectSuggested(_), .cancelled, .peerClosed:
            print("websocket")
        }
    }
}


extension WebRtcManager{
    
    static func fetchPrivateTurn(id:String, apiToken:String) async -> IceServerResponse?{
        let network = NetworkManager()
        let apiUrl = "https://rtc.live.cloudflare.com/v1/turn/keys/\(id)/credentials/generate-ice-servers"
        
        let data:IceServerResponse? = try? await network.fetch(url: apiUrl,method: .post,params: [
            "ttl":86400
        ],headers: [
            "authorization":"Bearer \(apiToken)"
        ])
        
        return data
    }
}


extension WebRtcManager{
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        guard let peerConnection else { return }
        peerConnection.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
    
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch {
                debugPrint("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
}

extension WebRtcManager{
    func call(uuid: UUID, callerName: String) async throws {
        try await self.liveCommunicationManager.call(uuid: uuid, callerName: callerName)
    }
    
    func reportNew(uuid: UUID, callerName: String) {
        self.liveCommunicationManager.reportNew(uuid: uuid, callerName: callerName)
    }
    
    func answer() async throws {
        try await self.liveCommunicationManager.answer()
    }
    
    func endCall() {
        self.liveCommunicationManager.endCall()
    }
}
