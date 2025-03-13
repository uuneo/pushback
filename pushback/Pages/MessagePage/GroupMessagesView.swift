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
    
    @State private var showMenu123:Bool = false

    
    var body: some View {
        List{
            
            if searchText.isEmpty{
    
                NavigationLink{
                    
                    AssistantPageView()
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .tabBar)
                    
                }label: {
                    MessageRow(message: chatHomeMessage, unreadCount: 0, customIcon: "chatgpt")
                }
            }
            
            ForEach(messages,id: \.id){ groupMessage in
                if let message = groupMessage.first{
                    NavigationLink {
                        
                       
                            MessageDetailPage(group: message.group)
                                .toolbar(.hidden, for: .tabBar)
                                .navigationTitle(message.group)
                
                        
                    } label: {
                        MessageRow(message: message, unreadCount: unRead(message))
                        
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
        }
        .hideNavBarOnSwipe(true)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
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
        
        VStack{
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
            }
        }
    }
    
    private func groupBody(_ message: Message) -> some View {
        var text = ""
        
        if let title = message.title {
            text = text + "\(title); "
        }
        
        if let subtitle = message.subtitle {
            text = text + "\(subtitle); "
        }
        
        if let body = message.body {
            text = text + body
        }
        
        return Text(text)
    }
}

#Preview {
    GroupMessagesView()
}
