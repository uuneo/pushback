

import SwiftUI
import MarkdownUI
import Splash
import RealmSwift

struct ChatMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let message: ChatMessage
    let showQuote:Bool
    
    private var codeHighlightColorScheme: Splash.Theme {
        switch colorScheme {
        case .dark:
            return .wwdc17(withFont: .init(size: 16))
        default:
            return .sunset(withFont: .init(size: 16))
        }
    }
    
    var quote:Message?{
        
        if let realm = try? Realm(){
            return realm.objects(Message.self).first(where: {$0.id.uuidString == message.messageId})
        }
        return nil
    }
    
    
    
    var body: some View {
        
        VStack{
            
            HStack{
                Spacer()
                Text("\(message.timestamp.formatString())" + "\n")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
           
            if message.request.count > 0 || (quote != nil &&  showQuote) {
                VStack{
                    if let quote = quote, showQuote{
                        HStack{
                            Spacer()
                            quoteView(quote: "\(quote.title ?? "")\(quote.body ?? "")")
                            Spacer()
                        }
                        .padding(.bottom, 5)
                    }
                    if message.request.count > 0{
                        HStack {
                            Spacer()
                            userMessageView
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
           
            
            if  !message.content.isEmpty {
                HStack{
                    assistantMessageView
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            
            
        }
        .padding(.vertical, 4)
    }
    
    
    
    // MARK: - View Components
    
    /// 用户消息视图
    private var userMessageView: some View {
        Text(message.request)
            .font(.system(size: 14))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.primary)
    }
    
    /// AI助手消息视图
    private var assistantMessageView: some View {
        Markdown(message.content)
            .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
            .markdownTheme(MarkdownTheme.enchantedTheme)
        
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            .foregroundColor(.primary)
        
    }
    
    @ViewBuilder
    func quoteView(quote:String)-> some View{
        HStack(spacing: 5) {
          
            
            Text("\(quote)")
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
    VStack {
        // 用户消息示例
        
        var content1:ChatMessage{
            let content = ChatMessage()
            content.request = "你好,我想了解一下 SwiftUI 的基础知识"
            return content
        }
        
        ChatMessageView(message: content1,showQuote: true)
        
        var content2:ChatMessage{
            let content = ChatMessage()
            content.request = """
            我很乐意为您介绍 SwiftUI 的基础知识!
            
            SwiftUI 是苹果推出的声明式UI框架,主要特点包括:
            
            1. 声明式语法
            2. 数据驱动
            3. 跨平台支持
            
            来看一个简单的代码示例:
            
            ```swift
            struct ContentView: View {
                var body: some View {
                    Text("Hello, SwiftUI!")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
            }
            ```
            
            您想从哪个方面开始了解呢?
            """
            return content
        }
        
        // AI助手回复示例
        ChatMessageView(message: content2,showQuote:true)
    }
}
