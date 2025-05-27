//
//  OpenChatManager.swift
//  pushback
//
//  Created by uuneo on 2025/3/4.
//

import Foundation
import OpenAI
import Defaults
import GRDB


final class openChatManager: ObservableObject {
    
    static let shared = openChatManager()
    
    @Published var currentRequest:String = ""
    @Published var currentContent:String = ""
 
    @Published var currentMessageId:String = UUID().uuidString
    @Published var isFocusedInput:Bool = false
    
    @Published var groupsCount:Int = 0
    @Published var messagesCount:Int = 0
    @Published var promptCount:Int = 0
    
    let local:URL
    let dbQueue:DatabasePool
    private var observationCancellable: AnyDatabaseCancellable?
    
    
    var currentChatMessage:ChatMessage{
        ChatMessage(id: currentMessageId, timestamp: .now, chat: "", request: currentRequest, content: "", message: AppManager.shared.askMessageId)
    }
    
    
    private init(){
        self.local = DatabaseManager.shared.localPath
        self.dbQueue = DatabaseManager.shared.dbQueue
        try! ChatGroup.createInit(dbQueue: dbQueue)
        try! ChatMessage.createInit(dbQueue: dbQueue)
        try! ChatPrompt.createInit(dbQueue: dbQueue)
    }
    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int,Int,Int) in
            var groupsCount:Int =  try ChatGroup.fetchCount(db)
            var goupsCurrent = try ChatGroup.filter(ChatGroup.Columns.current == true).fetchOne(db)
            var messagesCount:Int = try ChatMessage.filter(ChatMessage.Columns.chat == goupsCurrent?.id).fetchCount(db)
            var promptCount:Int = try ChatPrompt.fetchCount(db)
            return (groupsCount, messagesCount, promptCount)
        }
        
        observationCancellable = observation.start(
            in: dbQueue,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                print("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newUnreadCount in
                print("监听 SqlLite \(newUnreadCount)")
                
                DispatchQueue.main.async {
                    self?.groupsCount = newUnreadCount.0
                    self?.messagesCount = newUnreadCount.1
                    self?.promptCount = newUnreadCount.2
                }
            }
        )
    }
    
    func updateGroupName( groupId: String, newName: String) {
        do {
            try dbQueue.write { db in
                if var group = try ChatGroup.filter(Column("id") == groupId).fetchOne(db) {
                    group.name = newName
                    try group.update(db)
                }
            }
        } catch {
            print("更新失败: \(error)")
        }
    }
    
    var cancellableRequest:CancellableRequest? = nil
    
    
    
}

extension openChatManager{
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
        
        ///  增加system的前置参数
        if let promt = try? dbQueue.read({ db in
            try ChatPrompt.filter(Column("selected")).fetchOne(db)
        }){
            params.append(.system(.init(content: promt.content, name: promt.title)))
        }
        
        var inputText:String{
            
            if let messageId = messageId, let message = MessagesManager.shared.query(id: messageId){
                return message.search + "\n" + text
            }
            return text
        }
        
        
        /// 连续对话，获取前多少条的对话
        if (try? dbQueue.read({ db in
            try ChatGroup.filter(ChatGroup.Columns.current == true).fetchOne(db)
        })) != nil{
            return ChatQuery(messages: [.user(.init(content: .string(inputText)))], model: account.model)
        }
        
        
        
        let limit = Defaults[.historyMessageCount]
        if  let messageRaw = try? dbQueue.read({ db in
            try ChatMessage
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
        }){
            ///判断是否携带，如果连续对话，则继续判断，如果不是连续对话，必须携带，如果不是连续对话，判断历史记录里是否有
            if Defaults[.historyMessageBool]{
                
                for message in messageRaw{
                    params.append(.user(.init(content: .string(message.request))))
                    params.append(.assistant(.init(content: message.content)))
                    
                }
            }
            params.append(.user(.init(content: .string(inputText))))
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
    
    func chatsStream(text:String, account:AssistantAccount? = nil,onResult: @escaping @Sendable (Result<ChatStreamResult, Error>) -> Void, completion: (@Sendable (Error?) -> Void)?)  {
        guard let openchat = self.getReady(), let query = self.getHistoryParams(text: text,messageId: AppManager.shared.askMessageId) else {
            completion?(chatError.noConfig)
            return
        }
        self.cancellableRequest = openchat.chatsStream(query: query, onResult: onResult, completion: completion)
    }
    
    
    enum chatError: Error {
        case noConfig
    }
}
