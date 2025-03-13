

import SwiftUI
import RealmSwift
import Defaults

struct ChatMessageListView: View {
    
    // MARK: - Properties
    let chatgroup:ChatGroup?
    var currentRequest:String
    var currentContent:String
    let messageId:String?
    let isLoading: Bool
    let onEditMessage: (String) -> Void
    @ObservedResults(ChatMessage.self,where: {$0.chat == ""}) var messages
    
    
    
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
   
    
    @EnvironmentObject var keyboardHelper:KeyboardHeightHelper
    
    
    @State private var showHistory:Bool = false
    
    @State private var messageCount:Int = 10
    

    // MARK: - Body
    var body: some View {
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
                
                
                LazyVStack{
                    ForEach(messages.suffix(messageCount),id: \.id) { message in
                        ChatMessageView(message: message,isLoading: false)
                            .id(message.id)
                    }
                }
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 30)
            }
            
            .onAppear {
                scrollToBottom(proxy: scrollViewProxy,animation: false)
            }
            .onChange(of: currentContent) { newvalue in
                scrollToBottom(proxy: scrollViewProxy)
                PushbackManager.vibration(style: .soft)
            }
            .onChange(of: keyboardHelper.keyboardHeight) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    scrollToBottom(proxy: scrollViewProxy)
                }
            }
            .onChange(of: chatgroup?.id) { _ in
                scrollToBottom(proxy: scrollViewProxy)
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
        .animation(.default, value: currentRequest)
    }
    
    // MARK: - Helper Methods
    private func scrollToBottom(proxy: ScrollViewProxy, animation:Bool = true) {
        
        
        if let message = messages.last{
            if animation{
                withAnimation(.linear) {
                    proxy.scrollTo(message.id, anchor: .bottom)
                }
            }else{
                proxy.scrollTo(message.id, anchor: .bottom)
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
