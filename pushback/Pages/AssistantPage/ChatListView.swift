

import SwiftUI
import RealmSwift
import Defaults

struct ChatMessageListView: View {
    
    // MARK: - Properties
    let chatgroup:ChatGroup?
    let currentRequest:String
    let currentContent:String
    let messageId:String?
    let isLoading: Bool
    let onEditMessage: (String) -> Void
    @ObservedResults(ChatMessage.self,where: {$0.chat == ""}) var messages
    
    @Default(.historyMessageBool) var historyMessageBool
    
    init(chatGroup:ChatGroup?, currentRequest: String, currentContent: String, isLoading: Bool, messageId:String? = nil, onEditMessage: @escaping (String) -> Void) {
        self.chatgroup = chatGroup
        self.currentRequest = currentRequest
        self.currentContent = currentContent
        self.isLoading = isLoading
        self.onEditMessage = onEditMessage
        self.messageId = messageId
        if let chatGroup = chatGroup{
            self._messages = ObservedResults(ChatMessage.self,where: {$0.chat == chatGroup.id})
        }
        
    }
    
    @State private var selectedMessage: ChatMessage?
    @StateObject private var keyboardHelper = KeyboardHeightHelper()
    
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    
   
    
    let messageTem = ChatMessage()
    
    var currentMessage:ChatMessage{
        messageTem.request = currentRequest
        messageTem.content = currentContent
        messageTem.messageId = messageId
        return messageTem
    }
    
    
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            messageList
            
        }
        .sheet(item: $selectedMessage) { message in
            messageDetailSheet(message)
                .customPresentationCornerRadius(20)
        }
    }
    
    
    
    // MARK: - Private Views
    private var messageList: some View {
        ScrollViewReader { scrollViewProxy in
            
            ScrollView {
                if messages.count >= 10{
                    Section{
                        Button{
                            self.showHistory.toggle()
                        }label: {
                            HStack{
                                Text("\(min(messageCount,messages.count))/\(messages.count)")
                                Text("点击查看更多")
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.vertical)
                            
                                
                        }
                    }
                }
                
                
                ForEach(messages.suffix(messageCount),id: \.id) { message in
                    messageRow(message, showQuote: true)
                }
                
                if !currentRequest.isEmpty || messageId != nil{
                    var showQuote:Bool{
                        historyMessageBool ?
                        messages.suffix(messageCount).filter({$0.chat == messageId}).count == 0 : true
                    }
                    messageRow(currentMessage,showQuote: showQuote)
                }
                Section{
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 30)
                        .id("messageBottom")
                }
                
                
                
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    scrollToBottom(proxy: scrollViewProxy)
                }
            }
            .onChange(of: messages.count) {  _ in scrollToBottom(proxy: scrollViewProxy) }
            .onChange(of: currentMessage.content) { newvalue in
                scrollToBottom(proxy: scrollViewProxy)
                PushbackManager.vibration(style: .soft)
            }
            .onChange(of: chatgroup){ value in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    scrollToBottom(proxy: scrollViewProxy)
                }
            }
            .onChange(of: keyboardHelper.keyboardHeight) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    scrollToBottom(proxy: scrollViewProxy)
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
    
    private func messageRow(_ message: ChatMessage, showQuote:Bool = false) -> some View {
        ChatMessageView(message: message,showQuote: showQuote)
            .id(message.id)
            .contextMenu {
                MessageContextMenu(
                    message: message,
                    onCopy: copyMessage,
                    onSelect: { selectedMessage = message },
                    onEdit: { onEditMessage(message.content) }
                )
            }
    }
    
    
    private func messageDetailSheet(_ message: ChatMessage) -> some View {
        NavigationStack {
            ScrollView {
                Text(message.content)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("选择文本")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToBottom(proxy: ScrollViewProxy, id:String = "messageBottom") {
        withAnimation(.smooth) {
            proxy.scrollTo(id, anchor: .bottom)
        }
        
    }
    
    private func copyMessage(_ message: String) {
        Clipboard.shared.setString(message)
    }
    
}



private struct MessageContextMenu: View {
    let message: ChatMessage
    
    let onCopy: (String) -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var onAppear: (() -> Void)? = nil
    var onDisappear: (() -> Void)? = nil
    
    var body: some View {
        Group {
            Button(action: { onCopy(message.content) }) {
                Label("复制", systemImage: "doc.on.doc")
            }
            
            Button(action: onSelect) {
                Label("选择文本", systemImage: "selection.pin.in.out")
            }
        }
        .onAppear { onAppear?() }
        .onDisappear { onDisappear?() }
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
                        
                        ChatMessageView(message: message,showQuote: true)
                            .id(message.id)
                            .contextMenu {
                                
                            }
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
