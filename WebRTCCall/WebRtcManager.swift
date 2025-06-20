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






class WebRtcManager: NSObject, RTCPeerConnectionDelegate {
    
    
    private var factory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection!
    private var audioTrack: RTCAudioTrack!
    private let socket = WebSocketManager.shared
    
    override init() {
        super.init()
        initWebRTC()
        setupPeerConnection()
        addAudioTrack()
    }
    
    private func initWebRTC() {
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        
        configureAudioSession()
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

    private func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: CallConfig.default.webRTCIceServers)]
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    private func addAudioTrack() {
        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection.add(audioTrack, streamIds: ["stream0"])
    }

    func createOffer() async throws -> RTCSessionDescription  {
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
        
        let offer = try await peerConnection.offer(for: constraints)
        
        try await self.peerConnection.setLocalDescription(offer)
        
        print("Created offer SDP:\n\(offer.sdp)")
        
        return offer
    }

    func setRemoteSdp(sdp: String, type: RTCSdpType) {
        let desc = RTCSessionDescription(type: type, sdp: sdp)
        peerConnection.setRemoteDescription(desc, completionHandler: { error in
            print("Set remote SDP result: \(error?.localizedDescription ?? "Success")")
        })
    }

    func addIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection.add(candidate){_ in}
    }
    
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
       
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
       
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
       
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
       
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    
    static func fetchPublicTurn() async -> IceServerResponse? {
        let network = NetworkManager()
        let apiURL = "http://192.168.1.7:8080" + "/ICEServer"
        do{
            let config:IceServerResponse? = try await network.fetch(url: apiURL)
            return config
        }catch{
            debugPrint(error.localizedDescription)
            return nil
        }
        
    }
    
    
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



