//
//  protocols.swift
//  pushme
//
//  Created by lynn on 2025/6/19.
//
import Foundation


protocol CallerManager{
    var delegate: LiveCommunicationDelegate? { get set }
    func call(uuid: UUID, callerName: String) async throws
    func reportNew(uuid: UUID, callerName: String)
    func answer() async throws
    func endCall()
}


protocol LiveCommunicationDelegate: AnyObject{
    func callerManagerJoinConversation()
    func callerManagerDidEndCall()
}

