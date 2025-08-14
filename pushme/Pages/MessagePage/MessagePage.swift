//
//  MessagePage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults

struct MessagePage: View {
    @EnvironmentObject private var manager:AppManager
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @StateObject private var messageManager = MessagesManager.shared
    @State private var showDeleteAction:Bool = false
    @State private var selectAction:MessageAction? = nil
    var body: some View {
        
        ZStack{
            if manager.searchText.isEmpty{
                SingleMessagesView()
                    .if(showGroup) { GroupMessagesView() }
                    .transition(.opacity)
            }else{
                SearchMessageView(searchText: $manager.searchText)
                    .transition(.move(edge: .trailing))
            }
        }
        .navigationTitle( "消息")
        .animation(.easeInOut, value: showGroup)
        .searchable(text: $manager.searchText)
        .environmentObject(messageManager)
        .toolbar{
            
            if messageManager.groupMessages.count > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    
                    Menu {
                        ForEach( MessageAction.allCases, id: \.self){ item in
                            if item == .cancel{
                                Section{
                                    Button(role: .destructive){}label:{
                                        Label(item.localized, systemImage: "xmark.seal")
                                            .symbolRenderingMode(.palette)
                                            .customForegroundStyle(.accent, .primary)
                                    }
                                }
                            }else{
                                Button{
                                    self.selectAction = item
                                }label:{
                                    Label(item.localized, systemImage:  "trash" )
                                        .symbolRenderingMode(.palette)
                                        .customForegroundStyle(.accent, .primary)
                                }
                            }
                           
                        }
                    } label: {
                        Image(systemName: "trash.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                    }
                    
                    
                }
            }
            
            ToolbarItem( placement: .topBarLeading){
                Menu{
                    Section{
                        Button{
                            manager.router.append(.example)
                            Haptic.impact()
                        }label: {
                            Label("使用示例", systemImage: "questionmark.bubble")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.accent, Color.primary)
                        }
                    }
                    
                    Section{
                        
                        Button{
                            self.showGroup.toggle()
                            manager.selectGroup = nil
                            manager.selectId = nil
                            Haptic.impact()
                        }label:{
                            
                            Label(showGroup ? "列表模式" : "分组模式", systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.accent, .primary)
                                .animation(.easeInOut, value: showGroup)
                                .symbolEffect(delay: 0)
                        }
                    }
                    Section{
                        Button{
                            manager.router = [.assistant]
                            Haptic.impact()
                        }label: {
                            if #available(iOS 18.0, *){
                                Label("智能助手", systemImage: "apple.intelligence")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.accent, .primary)
                            }else{
                                Label("智能助手", systemImage: "atom")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.accent, .primary)
                            }
                           
                        }
                    }
                    
                    Section{
                        Button{
                            manager.router = [.pushtalk]
                            Haptic.impact()
                        }label: {
                            Label("语音对讲", systemImage: "person.line.dotted.person")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.accent, .primary)
                        }
                    }
                    
                    
                }label: {
                    Label("更多", systemImage: "shippingbox.circle")
                }
            }
            

        }
        .alert("确认删除", isPresented: Binding(get: { selectAction != nil }, set: { _ in selectAction = nil })) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let mode = selectAction {
                    Task.detached(priority: .userInitiated) {
                        await DatabaseManager.shared.delete(date: mode.date)
                    }
                }
                
            }
        } message: {
            if let selectAction{
                Text("此操作将删除 \( selectAction.localized ) 数据，且无法恢复。确定要继续吗？")
            }
            
        }
        
    }
    
    
    
}

#Preview {
    MessagePage()
}
