//
//  ChatInputView.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/1.
//

import SwiftUI
import Combine
import Defaults
import RealmSwift

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let isResponding: Bool
    let onSend: (String) -> Void
    let onPause: () -> Void
    let onSelectedPicture: () -> Void
    let onSelectedFile: () -> Void
    let onCapturePhoto: () -> Void
    let newMessageGroup:() -> Void
    var showHistoryGroup:()-> Void
    
    @State private var showPromptChooseView = false
    @FocusState private var isFocusedInput: Bool
    
    @Default(.historyMessageBool) var isHistoryMessage
     // MARK: - Computed Properties
    @ObservedResults(ChatPrompt.self, where: (\.isSelected)) var prompts
    
    var body: some View {
        VStack {
            HStack() {
                if let prompt = prompts.first {
                    PromptLabelView(prompt: prompt)
                }
            }.padding(.top, 5)
            HStack(spacing: 10) {
                inputField
                    .disabled(isLoading)
                rightActionButton
            }
            .padding(.horizontal)
            .padding(.top, 5)
//            .background(Color(.systemBackground))
            .animation(.default, value: text)
            
            
            HStack(spacing: 10){
                
                Label("对话列表", systemImage: "chevron.up")
                    .foregroundStyle(Color.primary)
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        PushbackManager.vibration(style: .heavy)
                        showHistoryGroup()
                    }
                    
                Label("连续对话", systemImage:  isHistoryMessage ? "lamp.desk.fill" : "lamp.desk")
                    .foregroundStyle(isHistoryMessage ? Color.accentColor : Color.primary)
                    .font(.system(size: 12))
                    .fontWeight(isHistoryMessage ? .bold : .light)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        PushbackManager.vibration(style: .heavy)
                        self.isHistoryMessage.toggle()
                    }
                
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.vertical, 8)
            
            
        }
        .background(.background)
        .cornerRadius(30, corners: [.topLeft, .topRight])
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
        if isResponding {
            // 暂停按钮
            Button(action: onPause) {
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                    .foregroundColor(.red)
                    .opacity(0.7)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .transition(.scale)
        } else if !text.isEmpty {
            // 发送按钮
            Button(action: {
                onSend(text)
                isFocusedInput = false
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
                onCapturePhoto: onCapturePhoto,
                newMessageGroup: newMessageGroup
            )
            .transition(.scale)
            
        }
    }
}

// MARK: - PromptLabelView
private struct PromptLabelView: View {
    
    let prompt: ChatPrompt
    var body: some View {
        HStack {
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
           
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
}


private struct AttachmentMenuView: View {
    var onSelectedPicture: () -> Void
    var onSelectedFile: () -> Void
    var onCapturePhoto: () -> Void
    var newMessageGroup: ()-> Void
    var body: some View {
        Menu {
            AttachmentMenuItem(title: "图片", icon: "photo", action: onSelectedPicture)
                .disabled(true)
            AttachmentMenuItem(title: "文件", icon: "doc", action: onSelectedFile)
                .disabled(true)
            AttachmentMenuItem(title: "拍照", icon: "camera", action: onCapturePhoto)
                .disabled(true)
            AttachmentMenuItem(title: "新对话", icon: "rectangle.3.group.bubble", action: newMessageGroup)
            
        } label: {
            attachmentMenuButton
        }
    }
    
    private var attachmentMenuButton: some View {
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



#Preview {
    ChatInputView(
        text: .constant("""
今天，DeepSeek 全新研发的推理模型 DeepSeek-R1-Lite 预览版正式上线。所有用户均可登录官方网页（chat.deepseek.com），一键开启与 R1-Lite 预览版模型的超强推理对话体验。DeepSeek R1 系列模型使用强化学习训练，推理过程包含大量反思和验证，思维链长度可达数万字。

"""),
        isLoading: false,
        isResponding: false,
        onSend: { message in
            print("发送消息: \(message)")
        },
        onPause: {
            print("暂停")
        },
        onSelectedPicture: {
            print("选择图片")
        },
        onSelectedFile: {
            print("选择文件")
        },
        onCapturePhoto: {
            print("选择拍照")
        },newMessageGroup:{
            
        }, showHistoryGroup: {
            
        })
}
