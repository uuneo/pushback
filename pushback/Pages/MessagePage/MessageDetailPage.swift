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
    let group:String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager:AppManager
    
    @Default(.showMessageAvatar) var showMessageAvatar

    // 分页相关状态
    @State private var messages:[Message]  = []
    @State private var messagesCount:Int = 100
    @State private var currentPage: Int = 0
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    @State private var showAllTTL:Bool = false
    
    var maxPage:Int{
      Int(ceil(Double(messagesCount) / Double(50)))
    }
    var body: some View {
        
        Group{
            if manager.searchText.isEmpty{
                ScrollViewReader{ proxy in
                    List{
                        ForEach(messages, id: \.id) { message in
                            
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
                            
                        }
                        
                        HStack{
                            ProgressView()
                            Text("正在加载中...")
                        }
                        .opacity(currentPage >= maxPage ? 0 : 1)
                        .listRowBackground(Color.clear)
                        .onAppear{
                            currentPage += 1
                            Task{
                                loadData(proxy: proxy)
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
                Text("\(min(currentPage * itemsPerPage, messages.count))/\(messagesCount)")
                    .font(.caption)
                    .pressEvents(onRelease: { _ in
                        withAnimation {
                            self.showAllTTL.toggle()
                        }
                        return true
                    })
            }
        }
        .onDisappear{
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
    
    
    private func loadData(proxy:ScrollViewProxy){
        guard let realm = try? Realm() else { return }
        let results = realm.objects(Message.self)
            .filter({$0.group == self.group}).sorted(by: {$0.createDate > $1.createDate})
        
        let size = min(self.currentPage * 50, results.count)
        DispatchQueue.main.async {
            self.messagesCount = results.count
            self.messages = Array(results.prefix(size))
            if let selectId = manager.selectId{
                proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
                manager.selectId = nil
                manager.selectGroup = nil
            }
        }
    }
}

#Preview {
    MessageDetailPage(group: "")
}
