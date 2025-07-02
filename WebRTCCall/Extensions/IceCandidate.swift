//
//  IceCandidate.swift
//  WebRTC-Demo
//
//  Created by Stasel on 20/02/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation
import WebRTC

struct SignalingMessage: Codable{
    var from: String
    var to: String
    var mode: Mode
    var turnId:String?
    var turnToken:String?
    var sdp: String?
    var ice: IceCandidate?
    
    
    enum Mode:String,Codable{
        case offer
        case answer
        case ready
        case ice
    }
    
    func json() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // 可选：格式化输出

        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}


/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
struct IceCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(from iceCandidate: RTCIceCandidate) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.sdp = iceCandidate.sdp
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}

struct IceServerResponse: Codable {
    let iceServers: [IceServer]
    struct IceServer: Codable {
        let urls: [String]
        let username: String?
        let credential: String?
    }
    
    var `default`: [RTCIceServer]{
        iceServers.compactMap { res in
            RTCIceServer(urlStrings: res.urls, username: res.username, credential: res.credential)
        }
    }
}
