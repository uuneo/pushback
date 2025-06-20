//
//  CallerManager.swift
//  pushme
//
//  Created by lynn on 2025/6/15.
//
import Foundation
import CallKit


class  CallBasicManager:CallerManager{
    func reportNew(uuid: UUID, callerName: String, complete: @escaping () -> Void) {
        
    }
    
    func answer() async throws {
        CXProvider.reportNewIncomingVoIPPushPayload([:]) { error in
        
        }
    }
    
    
    func call(uuid: UUID, callerName: String) async throws {
        
    }
    
    func endCall() {
        
    }
    
}
