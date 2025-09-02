//
//  TranslateMesssageView.swift
//  pushme
//
//  Created by lynn on 2025/6/21.
//

import SwiftUI
import Defaults
import OpenAI

struct TranslateMesssageView: View {
    var message:Message
    var scaleFactor: CGFloat
    var lang: String
    @Binding var translateResult: String
    
    @StateObject private var chatManager = openChatManager.shared
    @Default(.assistantAccouns) var assistantAccouns
    @State private var cancels:CancellableRequest? = nil
    
    var body: some View {
        VStack{
            if translateResult.isEmpty{
                Label("正在处理中...", systemImage: "rays")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.green, Color.primary)
                    .symbolEffect(.rotate)
            }else{
                MarkdownCustomView(content: translateResult, searchText: "", scaleFactor: scaleFactor)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                   
            }
           
        }
        .task {
            guard translateResult.isEmpty else { return }

            var datas: String = ""

            if let title = message.title, !title.isEmpty {
                datas += "\(title)/n"
            }

            if let subtitle = message.subtitle, !subtitle.isEmpty {
                datas += "\(subtitle)/n"
            }

            if let body = message.body, !body.isEmpty {
                datas += "\(body)"
            }

            sendMessage(datas)
        }
        .onDisappear{
            cancels?.cancelRequest()
        }
    }
    
    private func sendMessage(_ text: String) {
        
   
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            Toast.error(title: "需要配置大模型")
            translateResult = String(localized: "❗️需要配置大模型")
            
            return
        }
    
        self.cancels = chatManager.chatsStream(text: text, tips: .translate(lang)) { partialResult in
            switch partialResult {
            case .success(let result):
                
                if let res = result.choices.first?.delta.content {
                    DispatchQueue.main.async{
                        translateResult += res
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
                    translateResult = ""
                }
            }
        }
        
    }

}
