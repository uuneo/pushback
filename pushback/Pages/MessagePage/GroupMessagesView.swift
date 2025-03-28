//
//  GroupMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct GroupMessagesView: View {
    @ObservedSectionedResults(Message.self,
                              sectionKeyPath: \.group,
                              sortDescriptors: [SortDescriptor(keyPath: \Message.createDate, ascending: false)]) var messages
    
    @State private var searchText:String = ""
    
    @ObservedResults(ChatMessage.self, sortDescriptor: .init(keyPath: \ChatGroup.timestamp)) var chatMessages
    
    var chatHomeMessage:Message{
        return ChatMessage.getAssistant(chat: chatMessages.last)
    }
    @EnvironmentObject private var manager:PushbackManager
    @Default(.showAssistant) var showAssistant
    
    var body: some View {
        ScrollViewReader { proxy in
            List{
                
                if searchText.isEmpty && showAssistant{
                    
                    MessageRow(message: chatHomeMessage, unreadCount: 0, customIcon: "chatgpt")
                    
                        .pressEvents(onRelease: { value in
                            manager.messagePath = [.assistant]
                        })
                }
                
                ForEach(messages,id: \.id){ groupMessage in
                    if let message = groupMessage.first{
                       
                        MessageRow(message: message, unreadCount: unRead(message))
                            .id(message.group)
                            .pressEvents(onRelease: { value in
                                manager.messagePath = [.messageDetail(message.group)]
                            })
                            
                            .swipeActions(edge: .leading) {
                                Button {
                                    
                                    Task{ RealmManager.shared.read(message.group) }
                                    
                                } label: {
                                    
                                    Label( "标记", systemImage: unRead(message) == 0 ?  "envelope.open" : "envelope")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.primary)
                                    
                                }.tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    Task{
                                        RealmManager.shared.delete(group: message.group)
                                    }
                                    
                                } label: {
                                    
                                    Label( "删除", systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.primary)
                                    
                                }.tint(.red)
                            }
                           
                    }
                    
                    
                    
                }
            }
            .onAppear{  proxyTo(proxy: proxy, selectGroup: manager.selectGroup) }
            .onChange(of: manager.selectGroup){value in  proxyTo(proxy: proxy, selectGroup: value)}
        }
        .animation(.snappy(), value: messages.count)
        .hideNavBarOnSwipe(false)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        
        
    }
    
    private func proxyTo(proxy: ScrollViewProxy, selectGroup:String?){
        if let value = selectGroup{
            withAnimation {
                proxy.scrollTo(value,anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                manager.messagePath = [.messageDetail(value)]
            }
        }
    }
    

    private func unRead(_ message: Message) -> Int{
        do{
            return try Realm().objects(Message.self).where({$0.group == message.group && !$0.read}).count
        }catch{
            return 0
        }
        
    }
    
    
    
   
    
}


struct MessageRow: View {
    var message:Message
    var unreadCount: Int
    var customIcon:String = ""
    var body: some View {
        
        HStack {
            if unreadCount > 0 {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
            
            AvatarView(id: message.id.uuidString, icon: message.icon, customIcon: customIcon)
                .frame(width: 45, height: 45)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    if message.level > 2{
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                }
            
            
            VStack(alignment: .leading) {
                HStack {
                    Text(message.group)
                        .font(.headline.bold())
                        .foregroundStyle(.textBlack)
                    
                    Spacer()
                    
                    Text(message.createDate.agoFormatString())
                        .foregroundStyle(message.createDate.colorForDate())
                        .font(.caption2)
                }
                
                groupBody(message)
                    .font(.footnote)
                    .lineLimit(2)
                    .foregroundStyle(.gray)
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
                .imageScale(.small)
        }
    }
    
    private func groupBody(_ message: Message) -> some View {
        var text = Text("\("")")
        
        if let title = message.title {
            text = Text("\(title); ").foregroundColor(.blue)
        }
        
        if let subtitle = message.subtitle {
            text = text + Text("\(subtitle); ").foregroundColor(.gray)
        }
        
        if let body = message.body {
            
            text = text + Text("\(MarkdownCustomView.plain(text: body)); ").foregroundColor(.primary)
        }
        
        return text
    }
}

#Preview {
    GroupMessagesView()
}
