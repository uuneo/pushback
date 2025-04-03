

import SwiftUI
import Combine
import Defaults
import RealmSwift

struct ChatInputView: View {
    @EnvironmentObject private var chatManager:openChatManager
    @Binding var text: String
    
    let onSend: (String) -> Void
    let onSelectedPicture: () -> Void
    let onSelectedFile: () -> Void
    let onCapturePhoto: () -> Void
    
    @State private var showPromptChooseView = false
    @FocusState private var isFocusedInput: Bool
    
    @Default(.historyMessageBool) var isHistoryMessage
     // MARK: - Computed Properties
    @ObservedResults(ChatPrompt.self, where: (\.isSelected)) var prompts
    
   
   
    var body: some View {
        VStack {
           
            HStack() {
                PromptLabelView(prompt: prompts.first)
            }.padding(.top, 5)
            HStack(spacing: 10) {
                inputField
                    .disabled(chatManager.isLoading)
                rightActionButton
                    .disabled(chatManager.isLoading)
            }
            .padding(.horizontal)
            .padding(.top, 5)
//            .background(Color(.systemBackground))
            .animation(.default, value: text)
            
            
            HStack(spacing: 10){
                
                
                    
                Label("连续对话", systemImage:  isHistoryMessage ? "lamp.desk.fill" : "lamp.desk")
                    .foregroundStyle(isHistoryMessage ? Color.accentColor : Color.primary)
                    .font(.system(size: 12))
                    .fontWeight(isHistoryMessage ? .bold : .light)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        if !chatManager.isLoading{
                            PushbackManager.vibration(style: .heavy)
                            self.isHistoryMessage.toggle()
                        }
                       
                    }
                
                Spacer()
            
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            
        }
        .background(.background)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .onTapGesture {
            self.isFocusedInput = !chatManager.isLoading
        }
        .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: -5)
    }
    
    // MARK: - Subviews
    private var inputField: some View {
        HStack {
            TextField("给智能助手发消息", text: $text, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .focused($isFocusedInput)
                .frame(minHeight: 40)
                .font(.system(size: 14))
                .onChange(of: isFocusedInput){value in
                    
                    chatManager.isFocusedInput = value
                }
               
            PromptButtonView()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        
    }
    
    @ViewBuilder
    private var rightActionButton: some View {
        
        if !text.isEmpty {
            // 发送按钮
            Button(action: {
                
                self.text = text.trimmingCharacters(in: .whitespaces)
                if text.count > 1{
                    onSend(text)
                    isFocusedInput = false
                }else {
                    Toast.error(title: String(localized: "至少2个字符"))
                }
               
               
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .foregroundColor(.blue)
                    .opacity(0.7)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .transition(.scale)
        } else {
            
            // 附件菜单
            AttachmentMenuView(
                onSelectedPicture: onSelectedPicture,
                onSelectedFile: onSelectedFile,
                onCapturePhoto: onCapturePhoto
            )
            .transition(.scale)
            
        }
    }
    
   
}

// MARK: - PromptLabelView
private struct PromptLabelView: View {
    let prompt: ChatPrompt?

    @EnvironmentObject private var chatManager:openChatManager
    
    private var quote:Message?{
        guard let realm = try? Realm() else { return nil }
        return realm.objects(Message.self).first(where: {$0.id.uuidString == chatManager.messageId})
    }
    
    var body: some View {
        HStack {
            if let prompt {
                Menu{
                    Button(role: .destructive){
                        RealmManager.shared.realm { realm in
                            let datas = realm.objects(ChatPrompt.self)
                            for data in datas{
                                data.isSelected = false
                            }
                        }
                    }label: {
                        Label("清除", systemImage: "eraser")
                    }
                }label: {
                    
                    Text(prompt.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 2)
                }
            }
           
            
            Spacer()
            
           
            
            if let quote = quote{
                Menu{
                    Button(role: .destructive){
                        chatManager.messageId = nil
                    }label: {
                        Label("清除", systemImage: "eraser")
                    }
                }label: {
                    
                    quoteView(quote: "\(quote.title ?? "")\(quote.body ?? "")")
                }
            }
        }
        .padding(.horizontal)
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


private struct AttachmentMenuView: View {
    var onSelectedPicture: () -> Void
    var onSelectedFile: () -> Void
    var onCapturePhoto: () -> Void
     var body: some View {
        Menu {
            AttachmentMenuItem(title: String(localized: "图片"), icon: "photo", action: onSelectedPicture)
                .disabled(true)
            AttachmentMenuItem(title: String(localized: "文件"), icon: "doc", action: onSelectedFile)
                .disabled(true)
            AttachmentMenuItem(title: String(localized: "拍照"), icon: "camera", action: onCapturePhoto)
                .disabled(true)
            
           
            
        } label: {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundColor(.blue)
                .opacity(0.7)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                .padding(.trailing, 8)
                .transition(.scale)
        }
    }
    
}

private struct AttachmentMenuItem: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
    }
}



