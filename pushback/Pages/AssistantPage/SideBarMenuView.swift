//
//  SideBarMenuView.swift
//  pushback
//
//  Created by lynn on 2025/2/25.
//

import SwiftUI
import RealmSwift

struct SideBarMenuView: View {
    @ObservedResults(ChatGroup.self, sortDescriptor: SortDescriptor(keyPath: \ChatGroup.timestamp, ascending: false)) var chatGroups
    
    var chatGroupSection:[RealmManager.ChatMessageSection]{
        RealmManager.shared.getGroupedMessages(allMessages: chatGroups)
    }
    @Binding var showMenu:Bool
    @State private var text:String = ""
    @Binding var showSettings:Bool
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
                        RealmManager.shared.realm { realm in
                            if let group = chatgroup.thaw(){
                                group.name = text
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
            
        }
    }
    
    @ViewBuilder
    private func chatView(section: RealmManager.ChatMessageSection) -> some View{
        Section{
            LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                ForEach(section.messages, id: \.id){ chatgroup in
                    
                    HStack{
                        Button{
                            RealmManager.shared.realm { realm in
                                if let group = realm.objects(ChatGroup.self).where({$0.id == chatgroup.id}).first{
                                    group.current = true
                                }
                                for group in realm.objects(ChatGroup.self).where({$0.id != chatgroup.id}){
                                    group.current = false
                                }
                                
                            }
                            self.showMenu.toggle()
                        }label: {
                            
                            HStack{
                                Label(chatgroup.name, systemImage: "rectangle.3.group.bubble")
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
                            RealmManager.shared.realm { realm in
                                if let group = realm.objects(ChatGroup.self).first(where: {$0.id == chatgroup.id}){
                                    
                                    if let msg  =  realm.objects(ChatMessage.self).first(where: {$0.chat == group.id}){
                                        realm.delete(msg)
                                    }
                                    realm.delete(group)
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
}

#Preview {
    SideBarMenuView(showMenu: .constant(false),showSettings: .constant(false))
}
