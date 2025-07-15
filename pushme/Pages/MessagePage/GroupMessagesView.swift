//
//  GroupMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults
import GRDB

struct GroupMessagesView: View {
    
    @EnvironmentObject private var messageManager: MessagesManager
    @EnvironmentObject private var manager:AppManager
    
    var body: some View {
        ScrollViewReader { proxy in
            
            List{
                
                ForEach(messageManager.groupMessages, id: \.id){ message in
                    
                    MessageRow(message: message)
                        .VButton(onRelease: { value in
                            manager.router = [.messageDetail(message.group)]
                            return true
                        })
                        .id(message.group)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listSectionSeparator(.hidden)
                }
                if messageManager.showGroupLoading && messageManager.groupMessages.count == 0{
                    HStack{
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                .scaleEffect(1.5)
                            
                            Text("数据分组中...")
                                .foregroundColor(.primary)
                                .font(.body)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(24)
                    .shadow(radius: 10)
                    .listRowBackground(Color.clear)
                    
                }
                
            }
            .listStyle(.grouped)
            .animation(.default, value: messageManager.groupMessages)
            .onChange(of: messageManager.allCount) { _ in
                if let selectGroup = manager.selectGroup{
                    proxyTo(proxy: proxy, selectGroup: selectGroup)
                     DispatchQueue.main.async{
                        manager.router.append(.messageDetail(selectGroup))
                    }
                }
                
            }
        }
        
        
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
    
    
}


struct MessageRow: View {
    var message:Message
    var customIcon:String = ""
    @State private var unreadCount: Int = 0
    @EnvironmentObject private var messageManager:MessagesManager
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
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.message)
                .shadow(group: true)
        )
        .padding(.vertical, 8)
        .padding(.bottom, 3)
        .padding(.horizontal, 15)
        .swipeActions(edge: .leading) {
            Button {
                Task.detached(priority: .userInitiated) {
                    await DatabaseManager.shared.markAllRead(group: message.group)
                }
            } label: {
                
                Label( "标记", systemImage: unreadCount == 0 ?  "envelope.open" : "envelope")
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
                    
                    _ = await DatabaseManager.shared.delete(message, in: true)
                }
                
            } label: {
                
                Label( "删除", systemImage: "trash")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.primary)
                
            }.tint(.red)
        }
        .task { loadCount() }
        .onChange(of: messageManager.updateSign) { _ in
            loadCount()
        }
    }
    
    private func loadCount(){
        Task.detached(priority: .background) {
            let count = try await DatabaseManager.shared.dbPool.read { db in
                try Message
                    .filter(Message.Columns.group == message.group)
                    .filter(Message.Columns.read == false)
                    .fetchCount(db)
            }
             DispatchQueue.main.async{
                self.unreadCount = count
            }
        }
    }
    
    private func groupBody(_ message: Message) -> some View {
        var text = Text(verbatim: "")
        
        if let title = message.title {
            text = Text(verbatim: "\(title);").foregroundColor(.blue)
        }
        
        if let subtitle = message.subtitle {
            text = text + Text(verbatim: "\(subtitle);").foregroundColor(.gray)
        }
        
        if let body = message.body {
            
            text = text + Text(verbatim: "\(PBMarkdown.plain(body).replacingOccurrences(of: " ", with: ""))").foregroundColor(.primary)
        }
        
        return text
    }
}

#Preview {
    GroupMessagesView()
}


