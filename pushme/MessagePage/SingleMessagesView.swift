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
    @EnvironmentObject private var messageManager: MessagesManager
    
    @State private var showLoading:Bool = false
    @State private var scrollItem:String = ""
    @Namespace var namespace
    var body: some View {
        
        ScrollViewReader { proxy in
            List{
               
                    ForEach(messageManager.singleMessages, id: \.id) { message in
                        
                        MessageCard(message: message, searchText: "",showAllTTL: showAllTTL,showAvatar:showMessageAvatar){
                            withAnimation(.easeInOut) {
                                manager.selectMessage = message
                            }
                        }
                        .id(message.id)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                        
                        .onAppear{
                            if messageManager.singleMessages.count < messageManager.allCount &&
                                messageManager.singleMessages.last == message{
                                self.loadData(proxy: proxy, item: message)
                            }
                        }
                        
                    }
                
                
            }
            .listStyle(.grouped)
            .refreshable {
                self.loadData(proxy: proxy , limit: min(messageManager.singleMessages.count, 200))
            }
            .onChange(of: messageManager.updateSign) {  newValue in
                loadData(proxy: proxy, limit: max(messageManager.singleMessages.count, 50))
            }
        }
        
        .safeAreaInset(edge: .bottom, content: {
            HStack{
                Spacer()
                Text(verbatim: "\(messageManager.singleMessages.count) / \(max(messageManager.allCount, messageManager.singleMessages.count))")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial)
            }.opacity((messageManager.singleMessages.count == 0 || messageManager.singleMessages.count == messageManager.allCount) ? 0 : 1)
            
        })
        .task {
            self.loadData()
            Task.detached(priority: .background) {
                
                try? await DatabaseManager.shared.dbPool.write { db in
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
                proxy.scrollTo(selectId, anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                manager.selectId = nil
                manager.selectGroup = nil
            }
        }
    }
    
    private func loadData(proxy:ScrollViewProxy? = nil, limit:Int =  50, item:Message? = nil){
        self.showLoading = true
       Task.detached(priority: .userInitiated) {
            
           let results = await DatabaseManager.shared.query( limit: limit, item?.createDate)
            
             DispatchQueue.main.async {
 
                if item == nil {
                    
                    messageManager.singleMessages = results
                }else{
                    messageManager.singleMessages += results
                }
                if let selectId = manager.selectId{
                    proxy?.scrollTo(selectId, anchor: .center)
                    manager.selectId = nil
                    manager.selectGroup = nil
                }
                self.showLoading = false
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



