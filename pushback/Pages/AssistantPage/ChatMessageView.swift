

import SwiftUI
import RealmSwift
import Defaults

struct ChatMessageView: View {
    
    let message: ChatMessage
    let isLoading:Bool
    
    
    private var quote:Message?{
        guard let messageId = message.messageId, let realm = try? Realm() else { return nil }
        return realm.objects(Message.self).first(where: {$0.id.uuidString == messageId})
    }
    
    @Default(.showCodeViewColor) var showCodeViewColor
    
    
    var body: some View {
        
        VStack{
            
            timestampView
            
            
            if message.request.count > 0 || quote != nil {
                VStack{
                    if let quote = quote{
                        HStack{
                            Spacer()
                            QuoteView(message: quote)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                    if message.request.count > 0{
                        HStack {
                            Spacer()
                            
                            userMessageView
                                .if(isLoading) { view in
                                    view.lineLimit(2)
                                }
                                .assistantMenu(message.request)
                                
                            
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
            
            if  !message.content.isEmpty {
                HStack{
                    assistantMessageView
                        .assistantMenu(message.content)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
            
            
            
        }
        .padding(.vertical, 4)
    }
    
    
    
    // MARK: - View Components
    
    
    /// 时间戳视图
    private var timestampView: some View {
        HStack {
            Spacer()
            Text("\(message.timestamp.formatString())" + "\n")
                .font(.caption2)
                .foregroundStyle(.gray)
                .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
    
    /// 用户消息视图
    private var userMessageView: some View {
        MarkdownCustomView(content: message.request)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .overlay {
                Color.blue.opacity(0.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        
    }
    
    /// AI助手消息视图
    private var assistantMessageView: some View {
        MarkdownCustomView(content: message.content,showCodeViewColor: showCodeViewColor)
            .padding()
            .foregroundColor(.primary)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        
    }
    
}


extension View{
    
    func assistantMenu(_ text:String)-> some View{
        self
            .onTapGesture(count: 2){
                Clipboard.set(text)
                Toast.success(title: "复制成功")
            }
            .contextMenu{
                
                Section {
                    Button {
                        Task(priority: .high) {
                            guard let player = await AudioManager.shared.Speak(PBMarkdown.plain(text)) else { return }
                            player.play()
                        }
                    }label: {
                        Label("朗读内容",  systemImage: "waveform")
                            .symbolEffect(.variableColor)
                    }
                }
                
                Section{
                    Button(action: {
                        Clipboard.set(text)
                        Toast.success(title: "复制成功")
                    }) {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                }
                
            }
    }
}

struct QuoteView:View {
    var message:Message
    
    var body: some View {
        HStack(spacing: 5) {
            
            Text("\(message.search)")
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.caption2)
            
            Image(systemName: "quote.bubble")
                .foregroundColor(.gray)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ChatMessageView(message: ChatMessage(value: ["request" : "你好,我想了解一下 SwiftUI 的基础知识"]),isLoading: true)
}



