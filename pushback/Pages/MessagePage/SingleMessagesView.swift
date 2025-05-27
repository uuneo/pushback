//
//  SingleMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import GRDB
import Defaults

struct SingleMessagesView: View {
    
    @Default(.showMessageAvatar) var showMessageAvatar
    
    @State private var isLoading: Bool = false
    
 
    @State private var showAllTTL:Bool = false
    
    @EnvironmentObject private var manager:AppManager
    @StateObject private var messageManager = MessagesManager.shared


    @State private var messages:[Message]  = []
    
    var body: some View {
        
        ScrollViewReader { proxy in
            List{
                
                ForEach(messages, id: \.id) { message in
                    
                    MessageCard(message: message, searchText: manager.searchText,showAllTTL: showAllTTL,showAvatar:showMessageAvatar){
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
                    .swipeActions(edge: .trailing) {
                        Button {

                            withAnimation {
                                messages.removeAll(where: {$0.id == message.id})
                               
                            }
                            Task.detached(priority: .background){
                                _ = await messageManager.delete(message)
                            }
                        } label: {
                            
                            Label( "删除", systemImage: "trash")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.primary)
                            
                        }.tint(.red)
                    }
                    .onAppear{
                        if messages.last == message{
                            self.loadData(proxy: proxy, item: message)
                        }
                    }
                    
                }
                
                
            }
            .refreshable {
                self.loadData(proxy: proxy , limit: min(messages.count, 200))
            }
            .onChange(of: messageManager.updateSign) {  newValue in
                loadData(proxy: proxy, limit: max(messages.count, 50))
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            HStack{
                Spacer()
                Text("\(messages.count) / \(max(messageManager.allCount, messages.count))")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial)
            }.opacity((messages.count == 0 || messages.count == messageManager.allCount) ? 0 : 1)
            
        })
        .task {
            self.loadData()
            Task.detached(priority: .background) {
                
                try? await DatabaseManager.shared.dbQueue.write { db in
                    // 批量更新 read 字段为 true
                    try Message
                        .filter(Message.Columns.read == false)
                        .updateAll(db, [Message.Columns.read.set(to: true)])
                    
                    // 清除徽章
                    if Defaults[.badgeMode] == .auto {
                        UNUserNotificationCenter.current().setBadgeCount(0)
                    }
                }

            }
            
        }
    }
    
    private func proxyTo(proxy: ScrollViewProxy, selectId:String?){
        if let selectId = selectId{
            withAnimation {
                proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                manager.selectId = nil
                manager.selectGroup = nil
            }
        }
    }
    
    private func loadData(proxy:ScrollViewProxy? = nil, limit:Int =  50, item:Message? = nil){
       Task.detached(priority: .userInitiated) {
            
            let results = await messageManager.query( limit: limit, item?.createDate)
            
            DispatchQueue.main.async {
 
                if item == nil {
                    self.messages = results
                }else{
                    self.messages += results
                }
                if let selectId = manager.selectId{
                    proxy?.scrollTo(selectId, anchor: .center)
                    manager.selectId = nil
                    manager.selectGroup = nil
                }
            }
        }
    }
    
}

#Preview {
    SingleMessagesView()
}


struct BottomScrollDetector: View {
    let onBottomReached: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).maxY)
        }
        .frame(height: 0) // 不占空间
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
