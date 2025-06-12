//
//  protocols.swift
//  pushme
//
//  Created by lynn on 2025/6/19.
//
import Foundation


protocol CallerManager{
    func call(uuid: UUID, callerName: String) async throws
    func reportNew(uuid: UUID, callerName: String, complete: @escaping () -> Void)
    func answer() async throws 
    func endCall()
    
}

final class CallMainManager {
    static let shared = CallMainManager()
    
    public var manager:CallerManager
    private init(){
        if #available(iOS 17.4, *){
            self.manager = LiveCommunicationManager()
        }else{
            self.manager = CallBasicManager()
        }
    }
}


