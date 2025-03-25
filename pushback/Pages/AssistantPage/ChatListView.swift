

import SwiftUI
import RealmSwift
import Defaults
import Combine

struct ChatMessageListView: View {
    
    // MARK: - Properties
    let chatgroup:ChatGroup?
    @ObservedResults(ChatMessage.self,where: {$0.chat == ""}) var messages
    
    init(chatGroup:ChatGroup?, messageId:String? = nil) {
        self.chatgroup = chatGroup
        if let chatGroup = chatGroup{
            self._messages = ObservedResults(ChatMessage.self,where: {$0.chat == chatGroup.id})
        }
        
    }
    
    @EnvironmentObject var keyboardHelper:KeyboardHeightHelper
    @EnvironmentObject private var chatManager:openChatManager
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    
    let chatLastMessageId = "currentChatMessageId"
    
    let throttler = Throttler(delay: 0.1)
    
    @State private var offsetY: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            
            ScrollView {
                
                LazyVStack{
                    ForEach(messages,id: \.id) { message in
                        ChatMessageView(message: message,isLoading: false)
                            .id(message.id)
                    }
                    
                    VStack{
                        if chatManager.isLoading{
                            
                            ChatMessageView(message:   ChatMessage(value: ["id": chatLastMessageId, "request":chatManager.currentRequest,"content":chatManager.currentContent,"messageId": chatManager.messageId]),isLoading: false)
                        }
                        
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.clear)
                            .opacity(0.001)
                            .frame(height: 50)
                            .overlay(
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            let frame = proxy.frame(in: .global)
                                            offsetY = frame.maxY
                                        }
                                        .onChange(of: proxy.frame(in: .global).maxY) { newOffset in
                                            offsetY = newOffset
                                          
                                        }
                                }
                            )
                    }
                    .id(chatLastMessageId)
                }
                
                
                
                
            }
            .onAppear {
                DispatchQueue.main.async{
                    withAnimation(.snappy(duration: 0.1)){
                        scrollViewProxy.scrollTo(chatLastMessageId)
                    }
                }
                PushbackManager.vibration(style: .soft)
            }
            .onChange(of: keyboardHelper.keyboardHeight) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    scrollViewProxy.scrollTo(chatLastMessageId)
                }
            }
            .onChange(of: chatManager.currentContent){ value in
                throttler.throttle {
                    if offsetY < 830{
                        withAnimation(.snappy(duration: 0.1)){
                            scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                        }
                    }
                   
                }
            }
            .onChange(of: chatManager.isLoading){ value in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                }
            }
            .sheet(isPresented: $showHistory) {
                if let chatgroup = chatgroup{
                    HistoryMessage(showHistory: $showHistory, group: chatgroup.id)
                        .customPresentationCornerRadius(20)
                }else{
                    Spacer()
                        .onAppear{
                            self.showHistory.toggle()
                        }
                }
                
            }
        }
    }
    
    
}


struct HistoryMessage:View {
    @Binding var showHistory:Bool
    @ObservedResults(ChatMessage.self,sortDescriptor: .init(keyPath: \ChatMessage.timestamp, ascending: false)) var messages
    
    init(showHistory: Binding<Bool>, group:String) {
        self._showHistory = showHistory
        self._messages = ObservedResults(ChatMessage.self,where: {$0.chat == group},sortDescriptor: .init(keyPath: \ChatMessage.timestamp, ascending: false))
    }
    
    var body: some View {
        NavigationStack{
            ScrollView{
                LazyVStack{
                    ForEach(messages, id:\.id) { message in
                        
                        ChatMessageView(message: message,isLoading: false)
                            .id(message.id)
                    }
                    
                    Text("已加载全部数据")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
            }
            
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.showHistory = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(messages.count)")
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
            }
        }
    }
}


class Throttler {
    private var lastExecution: Date = .distantPast
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var pendingWorkItem: DispatchWorkItem?
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func throttle(_ action: @escaping () -> Void) {
        let now = Date()
        let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
        
        if timeSinceLastExecution >= delay {
            // 超过 1 秒，立即执行
            lastExecution = now
            action()
        } else {
            // 取消之前的任务，确保 1 秒内只执行最后一次
            pendingWorkItem?.cancel()
            
            let workItem = DispatchWorkItem {
                self.lastExecution = Date()
                action()
            }
            
            pendingWorkItem = workItem
            queue.asyncAfter(deadline: .now() + delay - timeSinceLastExecution, execute: workItem)
        }
    }
}
