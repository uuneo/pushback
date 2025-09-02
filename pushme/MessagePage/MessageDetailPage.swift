//
//  MessageDetailPage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults
import GRDB

struct MessageDetailPage: View {
    let group:String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager:AppManager
    @StateObject private var messageManager = MessagesManager.shared
    
    @Default(.showMessageAvatar) var showMessageAvatar

    // 分页相关状态
    @State private var messages:[Message]  = []
    @State private var allCount:Int = 1000000

    @State private var isLoading: Bool = false
    @State private var showAllTTL:Bool = false
    @State private var searchText:String = ""
    
    var body: some View {
        
        Group{
            if searchText.isEmpty{
                ScrollViewReader{ proxy in
                    List{
                        
                        ForEach(messages, id: \.id) { message in
                            
                            MessageCard(message: message, searchText: searchText,showAllTTL: showAllTTL,showAvatar: showMessageAvatar){
                                withAnimation(.easeInOut.speed(10)) {
                                    manager.selectMessage = message
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.hidden)
                            .id(message.id)
                            .onAppear{
                                if messages.count < allCount && messages.last == message{
                                    loadData(proxy: proxy,item: message)
                                }
                            }
                            .opacity(manager.selectMessage == message ? 0 : 1)
                            
                            
                        }
                        
                    }
                    .listStyle(.grouped)
                    .onChange(of: messageManager.updateSign) {  newValue in
                        loadData(proxy: proxy, limit: max(messages.count, 50))
                    }
                }
                
            }else {
                SearchMessageView(searchText: $searchText, group: group)
            }
        }
        .searchable(text: $searchText)
        .refreshable {
            loadData( limit: min(messages.count, 200))
        }
        .toolbar{
            ToolbarItem {
                Text(verbatim: "\(messages.count)/\(allCount)")
                    .font(.caption)
                    .VButton(onRelease: { _ in
                        withAnimation {
                            self.showAllTTL.toggle()
                        }
                        return true
                    })
            }
        }
        .task{
            loadData()
            
            Task.detached(priority: .background){
                try? await DatabaseManager.shared.dbPool.write { db in
                    // 更新指定 group 的未读消息为已读
                    let count =  try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.read == false)
                        .fetchCount(db)
                    
                    guard count > 0 else { return }
                    
                    try Message
                        .filter(Message.Columns.group == group)
                        .filter(Message.Columns.read == false)
                        .updateAll(db, [Message.Columns.read.set(to: true)])

                    // 重新计算未读数，更新通知角标（假设有同步环境）
                    if Defaults[.badgeMode] == .auto {
                        let unRead = try Message
                            .filter(Message.Columns.read == false)
                            .fetchCount(db)
                        UNUserNotificationCenter.current().setBadgeCount(unRead)
                    }
                }

            }
        }
        
        
    }
    
    
    private func loadData(proxy:ScrollViewProxy? = nil, limit:Int =  50, item:Message? = nil){
        
        
        Task.detached(priority: .userInitiated) {
            let results = await DatabaseManager.shared.query(group: self.group, limit: limit, item?.createDate)
            let count = DatabaseManager.shared.count(group: self.group)
             DispatchQueue.main.async {
                self.allCount = count
                if item == nil {
                    self.messages = results
                }else{
                    self.messages += results
                }
                if let selectId = manager.selectId{
                    withAnimation {
                        proxy?.scrollTo(selectId, anchor: .center)
                    }
                   
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                        manager.selectId = nil
                        manager.selectGroup = nil
                    }
                }
            }
        }
    }
}

#Preview {
    MessageDetailPage(group: "")
}
