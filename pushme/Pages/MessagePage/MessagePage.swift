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
            if !manager.isSearchActive{
                SingleMessagesView()
                    .if(showGroup) { GroupMessagesView() }
                    .transition(.move(edge: .leading))
            }else{
                SearchMessageView(searchText: $manager.searchText)
                    .transition(.move(edge: .trailing))
            }
        }
        .navigationTitle( "消息")
        .animation(.easeInOut, value:  manager.isSearchActive)
        .animation(.easeInOut, value: showGroup)
        .environmentObject(messageManager)
        .if(manager.isSearchActive){ $0.toolbar(.hidden, for: .navigationBar) }
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
            
//            ToolbarItem( placement: .topBarLeading) {
//                Button{
//                    manager.router.append(.example)
//                }label: {
//                    Label("使用示例", systemImage: "questionmark.bubble")
//                }
//                
//            }
//            
//            ToolbarItem( placement: .topBarLeading) {
//             
//                Button{
//                    self.showGroup.toggle()
//                    manager.selectGroup = nil
//                    manager.selectId = nil
//                    Haptic.impact()
//                }label:{
//                    
//                    Label("显示模式", systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
//                        .symbolRenderingMode(.palette)
//                        .customForegroundStyle(.accent, .primary)
//                        .animation(.easeInOut, value: showGroup)
//                        .symbolEffect(delay: 0)
//                }
//                
//                
//                
//                
//            }
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
