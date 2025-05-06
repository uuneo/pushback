//
//  OpenChatManager.swift
//  pushback
//
//  Created by uuneo on 2025/3/4.
//

import Foundation
import OpenAI
import Defaults
import RealmSwift


final class openChatManager: ObservableObject {
    
    static let shared = openChatManager()
    
    @Published var currentRequest:String = ""
    @Published var currentContent:String = ""
    @Published var isLoading:Bool = false
    @Published var inAssistant:Bool = false
    @Published var currentMessageId:String = UUID().uuidString
    @Published var messageId:String?
    @Published var isFocusedInput:Bool = false
    
    
    var currentChatMessage:ChatMessage{
        ChatMessage(value: ["id": currentMessageId, "request":currentRequest,"content": currentContent,"messageId": messageId])
    }
    
    
    private init(){}
    
    var cancellableRequest:CancellableRequest? = nil
    
    func test(account: AssistantAccount) async ->Bool{
        
        do{
            if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account.model.isEmpty{
                Log.debug(account)
                
                return false
            }
            
            
            guard let openchat = self.getReady(account: account) else {  return false }

            let query = ChatQuery(messages: [.user(.init(content: .string("Hello")))], model: account.model)
            
             _ = try await openchat.chats(query: query)
        
            return true
            
        }catch{
            debugPrint(error)
            return false
        }
        
       
    }
    
    func getHistoryParams(text: String, messageId:String? = nil)-> ChatQuery?{
        
        
        guard  let account =  Defaults[.assistantAccouns].first(where: {$0.current}) else {
            return nil
        }
        var params:[ChatQuery.ChatCompletionMessageParam] = []
        
        do{
            let realm = try Realm()
            
            ///  增加system的前置参数
            if let promt = realm.objects(ChatPrompt.self).first(where: (\.isSelected)){
                params.append(.system(.init(content: promt.content, name: promt.title)))
            }
            
            var inputText:String{
                if let message = realm.objects(Message.self).first(where: {$0.id.uuidString == messageId}){
                    return message.search + "\n" + text
                }
                return text
            }
            
           
            /// 连续对话，获取前多少条的对话
            guard let group = realm.objects(ChatGroup.self).first(where: {$0.current}) else {
                return ChatQuery(messages: [.user(.init(content: .string(inputText)))], model: account.model)
            }
            
            
            let messageRaw = realm.objects(ChatMessage.self).filter({$0.chat == group.id}).sorted(by: {$0.timestamp > $1.timestamp}).suffix( Defaults[.historyMessageCount])
           
            ///判断是否携带，如果连续对话，则继续判断，如果不是连续对话，必须携带，如果不是连续对话，判断历史记录里是否有
            if Defaults[.historyMessageBool]{
                
                for message in messageRaw{
                    params.append(.user(.init(content: .string(message.request))))
                    params.append(.assistant(.init(content: message.content)))
            
                }
               
            }
            params.append(.user(.init(content: .string(inputText))))
            
            
            return ChatQuery(messages: params, model: account.model)
            
        }catch{
            Log.error(error)
            Toast.error(title: "\(error.localizedDescription)")
          
            return ChatQuery(messages: [.user(.init(content: .string(text)))], model: account.model)
        }
    }
    
    
    func getReady(account:AssistantAccount? = nil) -> OpenAI?{
        if let account = account {
            
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }else {
            guard  let account = Defaults[.assistantAccouns].first(where: {$0.current}) else {
                return nil
            }
            let config = OpenAI.Configuration(token: account.key,host: account.host, basePath: account.basePath)
            
            return OpenAI(configuration: config)
        }
        
    }
    
    
    func chatsStream(text:String, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?)  {
        guard let openchat = self.getReady(), let query = self.getHistoryParams(text: text,messageId: self.messageId) else {
            completion?(chatError.noConfig)
            return
        }
        self.cancellableRequest = openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    
    enum chatError: Error {
        case noConfig
    }
    
}
