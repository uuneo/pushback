

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
                                .contextMenu{
                                    Button(action: { Clipboard.shared.setString(message.content) }) {
                                        Label("复制", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button{
                                        
                                    }label: {
                                        Label("选择文本", systemImage: "selection.pin.in.out")
                                    }
                                }
                            
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            
            
            if  !message.content.isEmpty {
                HStack{
                    assistantMessageView
                        .contextMenu{
                            Button(action: { Clipboard.shared.setString(message.content) }) {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                            
                        }
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



