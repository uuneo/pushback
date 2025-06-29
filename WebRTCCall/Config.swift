//
//  Config.swift
//  pushme
//
//  Created by lynn on 2025/6/15.
//

import Foundation

// Set this to the machine's address which runs the signaling server. Do not use 'localhost' or '127.0.0.1'
fileprivate let defaultSignalingServerUrl = URL(string: "ws://localhost:8080")!

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]

struct CallConfig {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]
    
    static let `default` = CallConfig(signalingServerUrl: defaultSignalingServerUrl, webRTCIceServers: defaultIceServers)
}
