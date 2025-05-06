

import SwiftUI
import RealmSwift
import Defaults
import Combine


struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    
    @EnvironmentObject private var chatManager:openChatManager
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    
    let chatLastMessageId = "currentChatMessageId"
    
    let throttler = Throttler(delay: 0.1)
    
    @State private var offsetY: CGFloat = 0
    
    var suffixCount:Int{
        min(messages.count, 10)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            
            ScrollView {
                
                if messages.count > suffixCount{
                    Button{
                        self.showHistory.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text("\(suffixCount)/\(messages.count)")
                                .padding(.trailing, 10)
                            Text("点击查看更多")
                           
                            Spacer()
                        }
                        .padding(.vertical)
                        .contentShape(Rectangle())
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    }
                }
                
            
                
                ForEach(messages.suffix(suffixCount),id: \.id) { message in
                    ChatMessageView(message: message,isLoading: chatManager.isLoading)
                        .id(message.id)
                }
                
                VStack{
                    if chatManager.isLoading{
                        
                        ChatMessageView(message:   chatManager.currentChatMessage,isLoading: chatManager.isLoading)
                    }
                    
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.clear)
                        .opacity(0.001)
                        .frame(height: 50)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: OffsetKey.self, value: proxy.frame(in: .global).maxY)
                            }
                        )
                        .onPreferenceChange(OffsetKey.self) { newValue in
                            offsetY = newValue
                        }
                }.id(chatLastMessageId)
                
            }
            .onAppear {
                DispatchQueue.main.async{
                    withAnimation(.snappy(duration: 0.1)){
                        scrollViewProxy.scrollTo(chatLastMessageId)
                    }
                }
                AppManager.vibration(style: .soft)
            }
            .onChange(of: chatManager.isFocusedInput) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    scrollViewProxy.scrollTo(chatLastMessageId)
                }
            }
            .onChange(of: chatManager.currentContent){ value in
                throttler.throttle {
                    if offsetY < 800{
                        withAnimation(.snappy(duration: 0.1)){
                            scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                        }
                    }
                   
                }
            }
            .onChange(of: chatManager.isLoading){ value in
                if offsetY < 800{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                        scrollViewProxy.scrollTo(chatLastMessageId, anchor: .bottom)
                    }
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
