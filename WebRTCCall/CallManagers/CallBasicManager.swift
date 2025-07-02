//
//  CallerManager.swift
//  pushme
//
//  Created by lynn on 2025/6/15.
//
import Foundation


class CallBasicManager:CallerManager{
    weak var delegate: LiveCommunicationDelegate?
    
    
    func reportNew(uuid: UUID, callerName: String) {
        
    }
    
    func answer() async throws {

    }
    
    
    func call(uuid: UUID, callerName: String) async throws {
        
    }
    
    func endCall() {
        
    }
    
}
