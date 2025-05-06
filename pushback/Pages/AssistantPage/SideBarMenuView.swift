//
//  SideBarMenuView.swift
//  pushback
//
//  Created by uuneo on 2025/2/25.
//

import SwiftUI
import RealmSwift

struct ChatMessageSection {
    var id:String = UUID().uuidString
    var title: String // 分组名称，例如 "[今天]"
    var messages: [ChatGroup]
}

struct SideBarMenuView: View {
    @ObservedResults(ChatGroup.self, sortDescriptor: SortDescriptor(keyPath: \ChatGroup.timestamp, ascending: false)) var chatGroups
    
    var chatGroupSection:[ChatMessageSection]{
        getGroupedMessages(allMessages: chatGroups)
    }
    @Binding var showMenu:Bool
    @State private var text:String = ""
    @State private var showChangeGroupName:Bool = false
    @State private var selectdChatGroup:ChatGroup? = nil
    var body: some View {
        NavigationStack{
            VStack{
                ScrollView {
                    if chatGroups.isEmpty{
                        emptyView
                    }else{
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(chatGroupSection, id: \.id){ section in
                                chatView(section: section)
                                    
                            }
                        }
                    }
                    
                }
                .scrollIndicators(.hidden)
                
            }
            .navigationTitle("最近使用")
            .searchable(text: $text)
            .popView(isPresented: $showChangeGroupName){
                withAnimation {
                    showChangeGroupName = false
                    self.selectdChatGroup = nil
                }
            }content: {
                if let chatgroup = selectdChatGroup{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        RealmManager.handler { realm in
                            if let group = realm.objects(ChatGroup.self).where({$0.id == chatgroup.id}).first{
                                realm.writeAsync {
                                    group.name = text
                                }
                            }
                        }
                    }
                }else {
                    Spacer()
                        .onAppear{
                            self.showChangeGroupName = false
                            self.selectdChatGroup = nil
                        }
                }
            }
            .toolbar{
                ToolbarItem {
                    Label("关闭", systemImage: "xmark.seal")
                        .foregroundStyle(.red)
                        .pressEvents(onRelease: { _ in
                            self.showMenu.toggle()
                            return true
                        })
                }
            }
            
        }
    }
    
    @ViewBuilder
    private func chatView(section: ChatMessageSection) -> some View{
        Section{
            LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(section.messages, id: \.id){ chatgroup in
                    
                    HStack{
                        Button{
                            RealmManager.handler{ realm in
                                
                                let results = realm.objects(ChatGroup.self)
                                
                                let current = results.where({$0.id == chatgroup.id})
                                
                                let noCurrent = results.where({$0.id != chatgroup.id})
                                
                                realm.writeAsync {
                                    current.setValue(true, forKey: "current")
                                    noCurrent.setValue(false, forKey: "current")
                                }

                                
                            }
                            self.showMenu.toggle()
                        }label: {
                            
                            HStack{
                                Label(chatgroup.name, systemImage: getleftIconName(group: chatgroup.id))
                                    .fontWeight(.medium)
                                    .lineLimit(1) // 限制为单行
                                    .truncationMode(.tail) // 超出部分用省略号
                                    .padding(.vertical, 10)
                                    .padding(.leading, 10)
                                    .foregroundColor(chatgroup.current ? .green : .primary)
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .imageScale(.large)
                                    .foregroundColor(chatgroup.current ? .green : .gray)
                                    
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background( .ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 10)
                            
                            
                            
                        }
                    }
                    .contextMenu {
                        Button{
                            self.selectdChatGroup = chatgroup
                            self.showChangeGroupName = true
                        }label:{
                            Text("重命名")
                        }
                        Button(role: .destructive){
                            RealmManager.handler{ realm in
                                if let group = realm.objects(ChatGroup.self).first(where: {$0.id == chatgroup.id}){
                                    
                                    let msgs = realm.objects(ChatMessage.self).filter({$0.chat == group.id})
                                    
                                    realm.writeAsync {
                                        realm.delete(msgs)
                                        realm.delete(group)
                                    }

                                }
                            }
                        }label:{
                            Text("删除")
                        }
                    }
                }
            }
            .padding(.vertical)
        }header: {
            HStack{
                
                Text(section.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .padding(.leading)
                
                Spacer()
                
            }
            .padding(.vertical, 5)
            .background( .ultraThinMaterial )
        }
        
        
        
    }
    
    private var emptyView: some View{
        VStack(alignment: .center){
            HStack{
                Spacer()
                Image(systemName: "plus.message")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70)
                Spacer()
            }
            .padding(.top, 50)
            .padding(.bottom, 20)
            HStack{
                Spacer()
                Text("无聊天")
                    .font(.title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.bottom)
            HStack(alignment: .center){
                Spacer()
                Text("当您与智能助手对话时，您的对话将显示在此处")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Spacer()
                
            }.padding(.bottom)
            HStack{
                Spacer()
                Button{
                    RealmManager.handler { realm in
                        let datas = realm.objects(ChatGroup.self)
                        
                        realm.writeAsync {
                            datas.setValue(false, forKey: "current")
                        }
                    }
                    self.showMenu.toggle()
                }label: {
                    Text("开始新聊天")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                
                Spacer()
            }
        }.padding()
    }
    
    private func getleftIconName(group:String)-> String{
        if let realm = try? Realm(){
           return  realm.objects(ChatMessage.self).filter({$0.messageId == group}).count == 0 ? "rectangle.3.group.bubble" :"message.badge.circle"
        }
        return "rectangle.3.group.bubble"
    }
    
    
    private func getGroupedMessages(allMessages: Results<ChatGroup>) -> [ChatMessageSection] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 定义时间分组规则
        let timeIntervals: [(title: String, start: Date, end: Date)] = [
            (String(localized: "今天"), today, calendar.date(byAdding: .day, value: 1, to: today)!),
            (String(localized: "昨天"), calendar.date(byAdding: .day, value: -1, to: today)!, today),
            (String(localized: "前天"), calendar.date(byAdding: .day, value: -2, to: today)!, calendar.date(byAdding: .day, value: -1, to: today)!),
            (String(localized: "2天前"), calendar.date(byAdding: .day, value: -3, to: today)!, calendar.date(byAdding: .day, value: -2, to: today)!),
            (String(localized: "一周前"), calendar.date(byAdding: .day, value: -7, to: today)!, calendar.date(byAdding: .day, value: -3, to: today)!),
            (String(localized: "两周前"), calendar.date(byAdding: .day, value: -14, to: today)!, calendar.date(byAdding: .day, value: -7, to: today)!),
            (String(localized: "1月前"), calendar.date(byAdding: .month, value: -1, to: today)!, calendar.date(byAdding: .day, value: -14, to: today)!),
            (String(localized: "3月前"), calendar.date(byAdding: .month, value: -3, to: today)!, calendar.date(byAdding: .month, value: -1, to: today)!),
            (String(localized: "半年前"), calendar.date(byAdding: .month, value: -6, to: today)!, calendar.date(byAdding: .month, value: -3, to: today)!)
        ]
        
        // 按时间分组
        var groupedMessages: [ChatMessageSection] = []
        
        for interval in timeIntervals {
            let messages = allMessages.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            if !messages.isEmpty {
                groupedMessages.append(ChatMessageSection(title: interval.title, messages: Array(messages)))
            }
        }
        
        return groupedMessages
    }
}

#Preview {
    SideBarMenuView(showMenu: .constant(false))
}
