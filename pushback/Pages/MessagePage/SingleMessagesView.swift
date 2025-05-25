//
//  SingleMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct SingleMessagesView: View {
    
    @Default(.showMessageAvatar) var showMessageAvatar
    
    @State private var currentPage: Int = 0
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    
 
    @State private var showAllTTL:Bool = false
    
    @EnvironmentObject private var manager:AppManager

    @State private var messages:[Message]  = []
    @State private var messagesCount:Int = 100
    
    var maxPage:Int{
      Int(ceil(Double(messagesCount) / Double(50)))
    }
    
    var body: some View {
        
        Group{
            
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
                            }
                        }
                        
                    }
                    
                    HStack{
                        Spacer()
                        ProgressView()
                        Text("正在加载中...")
                        Spacer()
                    }
                    .opacity(currentPage >= maxPage ? 0 : 1)
                        .listRowBackground(Color.clear)
                        .onAppear{
                            Task{
                                currentPage += 1
                                loadData(proxy: proxy)
                            }
                        }
                    
                }
                .refreshable {
                    currentPage = 1
                    self.loadData(proxy: proxy)
                }
            }
            
        }
        
        .task {
            Task.detached {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({!$0.read})
                    try? proxy.write {
                        datas.setValue(true, forKey: "read")
                    }
                    if Defaults[.badgeMode] == .auto{
                        UNUserNotificationCenter.current().setBadgeCount( 0 )
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
    
    private func loadData(proxy: ScrollViewProxy ){
        guard let realm = try? Realm() else { return }
        let results = realm.objects(Message.self).sorted(by: {$0.createDate > $1.createDate})
        let size = min(self.currentPage * 50, results.count)
        DispatchQueue.main.async {
            self.messagesCount = results.count
            self.messages = Array(results.prefix(size))
            if let selectId = manager.selectId{
                proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
                manager.selectId = nil
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
