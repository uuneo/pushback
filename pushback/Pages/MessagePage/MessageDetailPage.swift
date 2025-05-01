//
//  MessageDetailPage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct MessageDetailPage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager:PushbackManager
    
    @ObservedResults(Message.self) var messages
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.showAssistant) var showAssistant
    
   
    let group:String
    
    init(group: String) {
        
        self.group = group
        self._messages = ObservedResults(Message.self, where: { $0.group == group }, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
        
    }
    
    
    // 分页相关状态
    @State private var currentPage: Int = 1
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    @State private var showAllTTL:Bool = false
    
    
    var body: some View {
        
        Group{
            if manager.searchText.isEmpty{
                ScrollViewReader{ proxy in
                    List{
                        ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                            
                            MessageCard(message: message, searchText: manager.searchText,showAllTTL: showAllTTL,showAvatar: showMessageAvatar,showAssistant:showAssistant){
                                withAnimation(.easeInOut) {
                                    manager.selectMessage = message
                                }
                            }
                            .id(message.id)
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.visible)
                            
                        }.onDelete(perform: $messages.remove)
                        
                        Color.clear
                            .listRowBackground(Color.clear)
                            .onAppear{
                                if !self.isLoading {
                                    isLoading = true
                                    currentPage = min(Int(ceil(Double(messages.count) / Double(itemsPerPage))), currentPage + 1)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                                        isLoading = false
                                    }
                                   
                                }
                            }
                           
                    }
                    .onAppear{
                        manager.selectGroup = nil
                        
                        if let selectId = manager.selectId{
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                withAnimation {
                                    proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    manager.selectId = nil
                                }
                            }
                        }
                    }
                    
                }
                
            }else {
                List{
                    SearchMessageView(searchText: manager.searchText, group: group)
                }
            }
        }
        .searchable(text: $manager.searchText)
        .toolbar{
            ToolbarItem {
                Button{
                    withAnimation {
                        self.showAllTTL.toggle()
                    }
                    
                }label: {
                    Text("\(min(currentPage * itemsPerPage, messages.count))/\(messages.count)")
                        .font(.caption)
                }
            }
        }
        .task {
            Task.detached(priority: .background){
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({$0.group == group}).where({!$0.read})
                    try? proxy.write {
                        datas.setValue(true, forKey: "read")
                    }
                    if Defaults[.badgeMode] == .auto{
                        let unRead = proxy.objects(Message.self).where({!$0.read}).count
                        UNUserNotificationCenter.current().setBadgeCount( unRead )
                    }
                    
                }
            }
        }
        
        
    }
}

#Preview {
    MessageDetailPage(group: "")
}
