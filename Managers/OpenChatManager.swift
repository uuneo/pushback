//
//  OpenChatManager.swift
//  pushback
//
//  Created by lynn on 2025/3/4.
//

import Foundation
import OpenAI
import Defaults
import RealmSwift


final class openChatManager {
    
    static let shared = openChatManager()

    
    private init(){}
    
    var cancellableRequest:CancellableRequest? = nil
    
    func test(account: AssistantAccount,success:@escaping (Bool)-> Void){
        var isSuccess = false
        
        if account.host.isEmpty || account.key.isEmpty || account.basePath.isEmpty || account.model.isEmpty{
            debugPrint(account)
            success(false)
            return
        }
        
        
        guard let openchat = self.getReady(account: account) else {
            success(false)
            return
        }
        
        
        let query = ChatQuery(messages: [.user(.init(content: .string("Hello")))], model: account.model)
        
       
        
        self.cancellableRequest = openchat.chatsStream(query: query) { partialResult in
            
            switch partialResult {
            case .success(_):
                if !isSuccess{
                    success(true)
                    isSuccess = true
                }
            case .failure(let error):
                debugPrint(error)
                if !isSuccess{
                    success(false)
                    isSuccess = true
                }
            }
            self.cancellableRequest?.cancelRequest()
        }completion: { _ in}
    }
    
    func getHistoryParams(text: String)-> ChatQuery?{
        
        guard  let account =  Defaults[.assistantAccouns].first(where: {$0.current}) else {
            return nil
        }
        var params:[ChatQuery.ChatCompletionMessageParam] = []
        
        do{
            let realm = try Realm()
            
            @ObservedResults(ChatPrompt.self, where: (\.isSelected)) var prompts
            
            ///  增加system的前置参数
            if let promt = realm.objects(ChatPrompt.self).first(where: (\.isSelected)){
                params.append(.system(.init(content: promt.content, name: promt.title)))
            }
            /// 连续对话，获取前多少条的对话
            guard let group = realm.objects(ChatGroup.self).first(where: {$0.current}) else {
                return ChatQuery(messages: [.user(.init(content: .string(text)))], model: account.model)
            }
           
            if  Defaults[.historyMessageBool]{
                let messageRaw = realm.objects(ChatMessage.self).filter({$0.chat == group.id}).sorted(by: {$0.timestamp > $1.timestamp}).suffix( Defaults[.historyMessageCount])
                
                for message in messageRaw{
                    params.append(.user(.init(content: .string(message.request))))
                    params.append(.assistant(.init(content: message.content)))
                }
            }
            
            
            params.append(.user(.init(content: .string(text))))
            
            return ChatQuery(messages: params, model: account.model)
            
        }catch{
            Log.error(error)
            Toast.shared.present(title: "\(error.localizedDescription)", symbol: .error)
        }
        return ChatQuery(messages: params, model: account.model)
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
    
    
    func chatsStream(text:String, account:AssistantAccount? = nil,onResult: @escaping (Result<ChatStreamResult, Error>) -> Void, completion: ((Error?) -> Void)?)  {
        guard let openchat = self.getReady(), let query = self.getHistoryParams(text: text) else {
            completion?(chatError.noConfig)
            return
        }
        self.cancellableRequest = openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    
    enum chatError: Error {
        case noConfig
    }
    
}
