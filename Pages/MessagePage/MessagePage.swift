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
        
        Group{
            if manager.searchText.isEmpty{
                SingleMessagesView()
                    .if(showGroup) {
                        GroupMessagesView()
                    }
            }else{
                SearchMessageView(searchText: $manager.searchText)
            }
        }
        .navigationTitle( "消息")
        .environmentObject(messageManager)
        .searchable(text: $manager.searchText)
        .listRowSpacing(10)
        .toolbar{
            
            ToolbarItem( placement: .topBarTrailing) {
                
                Menu {
                    Section{
                        Button{
                            self.showGroup.toggle()
                            manager.selectGroup = nil
                            manager.selectId = nil
                            Haptic.impact()
                        }label:{
                            
                            Label("切换显示模式", systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                                .animation(.easeInOut, value: showGroup)
                                .symbolEffect(delay: 0)
                        }
                    }
                    Section{
                        Button{
                            if servers.count > 0{
                                manager.router = [.example]
                            }else{
                                manager.router = [.server]
                            }
                            Haptic.impact()
                        }label:{
                            
                            Label("教程示例", systemImage: "menucard")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                                .symbolEffect(delay: 0)
                                .padding(.horizontal, 10)
                        }
                    }
                    Section{
                        Button{
                            manager.router.append(.assistant)
                            Haptic.impact()
                        }label: {
                            Group{
                                if #available(iOS 18.0, *){
                                    Label("智能助手", systemImage: "apple.intelligence")
                                }else{
                                    Label( "智能助手", systemImage: "bonjour")
                                }
                            }
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .symbolEffect(delay: 0)
                        }
                    }
                    
                    Section{
                        Button{
                            manager.router.append(.call)
                            Haptic.impact()
                        }label: {
                            Label("语音", systemImage: "phone.and.waveform.fill")
                                .symbolRenderingMode(.palette)
                                .symbolEffect(.variableColor)
                                .foregroundStyle( .green, .primary)
                        }
                    }
                    
                    
                } label: {
                    Image(systemName: "slider.horizontal.2.square.on.square")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .symbolEffect(delay: 5)
                }

                
                
                
            }
           
            if messageManager.groupMessages.count > 0 {
                ToolbarItem(placement: .topBarLeading) {
                    
                    Menu {
                        ForEach( MessageAction.allCases, id: \.self){ item in
                            if item == .cancel{
                                Section{
                                    Button(role: .destructive){}label:{
                                        Label(item.localized, systemImage: "xmark.seal")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.green, Color.primary)
                                    }
                                }
                            }else{
                                Button{
                                    self.selectAction = item
                                }label:{
                                    Label(item.localized, systemImage:  "trash" )
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
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
    
           
            
            
        }
        .alert("确认删除", isPresented: Binding(get: {
            selectAction != nil
        }, set: { _ in
            selectAction = nil
        })) {
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
