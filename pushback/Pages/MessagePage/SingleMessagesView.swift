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
    
    @ObservedResults(Message.self,sortDescriptor: SortDescriptor(keyPath: \Message.createDate, ascending: false)) var messages
    @Default(.showMessageAvatar) var showMessageAvatar
    
    @State private var currentPage: Int = 1
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    
 
    @State private var showAllTTL:Bool = false
    
    @EnvironmentObject private var manager:AppManager

    var currentMessage:[Message]{
        Array(messages.prefix(currentPage * itemsPerPage))
    }
    
    var body: some View {
        
        Group{
            
                ScrollViewReader { proxy in
                    List{
                    
                        ForEach(currentMessage, id: \.id) { message in
                            
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
                        DispatchQueue.main.async{
                            proxyTo(proxy: proxy, selectId: manager.selectId )
                        }
                    }
                    .onChange(of: manager.selectId){ value in
                        DispatchQueue.main.async{
                            proxyTo(proxy: proxy, selectId: value )
                        }
                    }
                }
            
        }
        
        .task {
            Task.detached(priority: .background) {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({!$0.read})
                    try? proxy.write {
                        datas.setValue(true, forKey: "read")
                    }
                    if Defaults[.badgeMode] == .auto{
                        UNUserNotificationCenter.current().setBadgeCount( -1 )
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
