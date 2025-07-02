//
//  CallHighManager.swift
//  pushme
//
//  Created by lynn on 2025/6/19.
//

import Foundation
import LiveCommunicationKit
import UIKit
import AVFAudio
 


@available(iOS 17.4, *)
class LiveCommunicationManager: CallerManager{
    
    var delegate: LiveCommunicationDelegate?
    

    var manager: ConversationManager!
     
    var currentCallID: UUID?
    
    init() {
        createNew()
        manager.delegate = self
    }
    
    func createNew(){
        
        if manager != nil {
           return
        }
        
        let config = ConversationManager.Configuration(
            ringtoneName: "call.caf",
            iconTemplateImageData: UIImage(named: "logo")?.pngData(), // 图标的 PNG 数据
            maximumConversationGroups: 1, // 最大对话组数
            maximumConversationsPerConversationGroup: 1, // 每个对话组内最大对话数
            includesConversationInRecents: false, // 是否在通话记录中显示
            supportsVideo: true, // 是否支持视频
            supportedHandleTypes: [.generic, .emailAddress, .phoneNumber] // 支持的通话类型
        
        )
         
        manager = ConversationManager.init(configuration: config)
       
    }
    
    
    func call(uuid: UUID, callerName: String) async throws {
        createNew()
        self.currentCallID = uuid
        let local = Handle(type: .generic, value: callerName, displayName: callerName)
        let action = StartConversationAction(conversationUUID: uuid, handles: [local], isVideo: false)
        try await manager.perform([action])
        
        try await Task.sleep(for: .seconds(5))
        for conversation in manager.conversations {
            if conversation.uuid == uuid {
                // Report conversation status.
                manager.reportConversationEvent(.conversationConnected(Date()), for: conversation)
            }
        }
    }
    
    func answer() async throws {
        guard let id = self.currentCallID else { return }
        let action = JoinConversationAction(conversationUUID: id)
        try await manager.perform([action])
        
    }
    func reportNew(uuid: UUID, callerName: String){
        createNew()
        self.currentCallID = uuid
        Task.detached(priority: .userInitiated) {
           
            let local = Handle(type: .generic, value: callerName, displayName: callerName)
            

            let update = Conversation.Update(activeRemoteMembers: [local])
             
            
            do {
                try await self.manager.reportNewIncomingConversation(uuid: uuid, update: update)

                print("成功报告新来电")
            } catch {
                print("报告新来电失败: \(error.localizedDescription)")
            }
        }
    }
     
    func endCall(){
        for conversation in manager.conversations {
            if conversation.uuid == self.currentCallID {
                // Report conversation status.
                manager.reportConversationEvent(.conversationEnded(.now, .remoteEnded), for: conversation)
                
            }
        }
    }
}

@available(iOS 17.4, *)
extension LiveCommunicationManager: ConversationManagerDelegate {
    func conversationManager(_ manager: ConversationManager, conversationChanged conversation: Conversation) {
       
        Log.info("会话状态改变了", conversation.state)

    }
     
    func conversationManagerDidBegin(_ manager: ConversationManager) {
        Log.info("会话已经开始了")
    }
     
    func conversationManagerDidReset(_ manager: ConversationManager) {
        Log.info("会话将要清除了")
    }
     
    func conversationManager(_ manager: ConversationManager, perform action: ConversationAction) {
        Log.info("操作按钮：", action)
        
       
        
        if action is JoinConversationAction{
            delegate?.callerManagerJoinConversation()
        }
        
        action.fulfill()
        
//        if action is EndConversationAction{
//            action.fulfill()
//        }else if action is JoinConversationAction{
//            action.fulfill()
//        }else if action is MuteConversationAction{
//            action.fulfill()
//        }else if action is UnmergeConversationAction{
//            action.fulfill()
//        }
//        
    }
     
    func conversationManager(_ manager: ConversationManager, timedOutPerforming action: ConversationAction) {
        print("会话超时了")
    }
     
    func conversationManager(_ manager: ConversationManager, didActivate audioSession: AVAudioSession) {
        print("会话激活了")
        do{
            try audioSession.setCategory(.playAndRecord, options: [.allowBluetooth, .duckOthers])
            try audioSession.setMode(.voiceChat) // 或者 .voiceCall
            try audioSession.overrideOutputAudioPort(.none)
            try audioSession.setActive(true)
        }catch{
            debugPrint(error.localizedDescription)
        }
        
    }
     
    func conversationManager(_ manager: ConversationManager, didDeactivate audioSession: AVAudioSession) {
        print("会话结束")
        delegate?.callerManagerDidEndCall()
    }
}
