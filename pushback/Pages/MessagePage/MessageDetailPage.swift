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
    @EnvironmentObject private var manager:AppManager
    
    @ObservedResults(Message.self) var messages
    @Default(.showMessageAvatar) var showMessageAvatar

    
   
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
                            
                            MessageCard(message: message, searchText: manager.searchText,showAllTTL: showAllTTL,showAvatar: showMessageAvatar){
                                withAnimation(.easeInOut) {
                                    manager.selectMessage = message
                                }
                            }
                            .id(message.id)
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.visible)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    Task(priority: .high) {
                                        guard let player = await AudioManager.shared.Speak(message.voiceText) else {
                                            return
                                        }
                                        player.play()
                                    }
                                }label: {
                                    Label("朗读内容",  systemImage: "waveform")
                                        .symbolEffect(.variableColor)
                                }.tint(.green)
                            }
                            
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
                Text("\(min(currentPage * itemsPerPage, messages.count))/\(messages.count)")
                    .font(.caption)
                    .pressEvents(onRelease: { _ in
                        withAnimation {
                            self.showAllTTL.toggle()
                        }
                        return true
                    })
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
                        UNUserNotificationCenter.current().setBadgeCount( unRead == 0 ? -1 : unRead )
                    }
                    
                }
            }
        }
        
        
    }
}

#Preview {
    MessageDetailPage(group: "")
}
