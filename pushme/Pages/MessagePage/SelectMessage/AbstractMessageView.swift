//
//  AbstractMessageView.swift
//  pushme
//
//  Created by lynn on 2025/6/22.
//

import SwiftUI
import Defaults
import OpenAI

struct AbstractMessageView: View {
    var message:Message
    var scaleFactor: CGFloat
    var lang: String
    @Binding var abstractResult: String
    @StateObject private var chatManager = openChatManager.shared
    @Default(.assistantAccouns) var assistantAccouns
    @State private var cancels:CancellableRequest? = nil
    
    var body: some View {
        VStack{
            if abstractResult.isEmpty{
                Label("正在处理中...", systemImage: "rays")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.green, Color.primary)
                    .symbolEffect(.rotate)
            }else{
                MarkdownCustomView(content: abstractResult, searchText: "", scaleFactor: scaleFactor)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                    
            }
           
        }
        .task {
            guard abstractResult.isEmpty else { return }

            sendMessage(message.search.trimmingSpaceAndNewLines)
        }
        .onDisappear{
            cancels?.cancelRequest()
        }
    }
    
    private func sendMessage(_ text: String) {
        
   
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            Toast.error(title: "需要配置大模型")
            abstractResult = String(localized: "❗️需要配置大模型")
            
            return
        }
    
        self.cancels = chatManager.chatsStream(text: text, tips: .abstract(lang)) { partialResult in
            switch partialResult {
            case .success(let result):
                
                if let res = result.choices.first?.delta.content {
                    DispatchQueue.main.async{
                        abstractResult += res
                        Haptic.selection(limitFrequency: true)
                    }
                }
            case .failure(let error):
                //Handle chunk error here
                Log.error(error)
                Toast.error(title: "发生错误\(error.localizedDescription)")
            }
            
            
        }completion: { err in
            if err != nil{
                DispatchQueue.main.async{
                    abstractResult = ""
                }
            }
        }
        
    }

}
