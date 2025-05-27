//
//  GroupMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults

struct GroupMessagesView: View {
    
    @EnvironmentObject private var messageManager: MessagesManager
    @EnvironmentObject private var manager:AppManager

    var body: some View {
        ScrollViewReader { proxy in
            List{
             
                ForEach(messageManager.groupMessages, id: \.id){ message in
       
                    MessageRow(message: message, unreadCount: unRead(message))
                        .pressEvents(onRelease: { value in
                            manager.router = [.messageDetail(message.group)]
                            return true
                        })
                        .id(message.group)
                        .swipeActions(edge: .leading) {
                            Button {
                                messageManager.markAllRead(group: message.group)
                            } label: {
                                
                                Label( "标记", systemImage: unRead(message) == 0 ?  "envelope.open" : "envelope")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.primary)
                                
                            }.tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {

                                withAnimation {
                                    messageManager.groupMessages.removeAll(where: {$0.id == message.id})
                                   
                                }
                                
                                Task.detached(priority: .background){
                                
                                    _ = await messageManager.deleteAll(inGroup: message.group)
                                }
                               
                            } label: {
                                
                                Label( "删除", systemImage: "trash")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.primary)
                                
                            }.tint(.red)
                        }
                    
                }
                
                HStack{
                    Spacer()
                    ProgressView()
                    Text("正在加载中...")
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .opacity(messageManager.showGroupLoading ? 1 : 0)
                .animation(.easeInOut, value: messageManager.showGroupLoading)
                
            }
            
        }
        .animation(.default, value: messageManager.groupMessages)
        
    }
    
    
    private func proxyTo(proxy: ScrollViewProxy, selectGroup:String?){
        if let value = selectGroup{
            withAnimation {
                proxy.scrollTo(value,anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                manager.router = [.messageDetail(value)]
            }
           
        }
    }
    

    private func unRead(_ message: Message) -> Int{
        messageManager.unreadCount(group: message.group)
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
            
            AvatarView(icon: message.icon, customIcon: customIcon)
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
            text = Text("\(title);").foregroundColor(.blue)
        }
        
        if let subtitle = message.subtitle {
            text = text + Text("\(subtitle);").foregroundColor(.gray)
        }
        
        if let body = message.body {
            
            text = text + Text("\(PBMarkdown.plain(body).replacingOccurrences(of: " ", with: ""))").foregroundColor(.primary)
        }
        
        return text
    }
}

#Preview {
    GroupMessagesView()
}


