//
//  AssistantSettingsView.swift
//  pushback
//
//  Created by uuneo on 2025/2/26.
//

import SwiftUI
import Defaults
import RealmSwift

struct AssistantSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var chatManager: openChatManager
    
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.historyMessageCount) var historyMessageCount
    @Default(.showCodeViewColor) var showCodeViewColor
    
    @State private var showDeleteOk:Bool = false
    @State private var isSecured = true
    @State private var isTestingAPI = false
    @State private var selectAccount:AssistantAccount? = nil
    @State private var addAccount:AssistantAccount? = nil
    
    
    init(account: AssistantAccount? = nil) {
        if let account{
            self._addAccount = State(wrappedValue: account)
        }
       
    }
    
    
    var body: some View {

            List{
                Section{
                    
                    Button{
                        self.selectAccount =  AssistantAccount(host: "api.openai.com", basePath: "/v1", key: "", model: "gpt-4o-mini")
                    }label: {
                        HStack{
                            Label("增加新账户", systemImage: "person.badge.plus")
                            Spacer()
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 0))
                    }
                    
                    
                    
                    ForEach(assistantAccouns,id: \.id){ account in
                        HStack{
                            HStack{
                                Text("\(account.name)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fontWeight( account.current ? .bold : .light)
                                    .foregroundStyle(account.current ? .green : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical)
                            .padding(.leading, 5)
                            .frame(width: 100)
                            
                            
                            VStack{
                                HStack{
                                    Image(systemName: "network")
                                        .imageScale(.small)
                                    Text("\(account.host)")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                                .padding(.bottom, 5)
                                HStack{
                                    Image(systemName: "slider.horizontal.2.square.badge.arrow.down")
                                        .imageScale(.small)
                                    Text("\(account.model)")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                                
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                                .imageScale(.small)
                        }
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets())
                        .padding(10)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(.background)
                                .background(.ultraThinMaterial)
                        )
                        .onTapGesture(perform: {
                            self.selectAccount = account
                        })
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                
                                if let index = assistantAccouns.firstIndex(where: {$0.current}){
                                    assistantAccouns[index].current = false
                                }
                                
                                if let index = assistantAccouns.firstIndex(where: {$0.id == account.id}){
                                    assistantAccouns[index].current = true
                                }
            
                            } label: {
                                Label("默认", systemImage: "cursorarrow.click.2")
                            }.tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = assistantAccouns.firstIndex(where: {$0.id == account.id}){
                                    assistantAccouns.remove(at: index)
                                }
                                AppManager.vibration(style: .heavy)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        
                        
                    }
                    .onMove { indexSet, index in
                        assistantAccouns.move(fromOffsets: indexSet, toOffset: index)
                    }
                    
                }header: {
                    Text("账户列表")
                }
                
                
                Section("AI 助手") {
                    
                    HStack{
                        
                        Toggle(isOn: $showCodeViewColor) {
                            Label("彩色代码", systemImage: "theatermask.and.paintbrush")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.primary, showCodeViewColor ? .red : .gray)
                        }
                    }
                    
                    Stepper(
                        value: $historyMessageCount,
                        in: 1...50,
                        step: 1
                    ) {
                        HStack {
                            Label("历史消息数量", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(historyMessageCount)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("设置每次对话时包含的历史消息数量，数量越多上下文越完整，但会增加 Token 消耗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                
                Section("数据管理") {
                    Button(role: .destructive) {
                        self.showDeleteOk = true
                    } label: {
                        Label("清除所有数据", systemImage: "trash")
                        Spacer()
                    }
                }
               
            }
            .navigationTitle( "智能助手")
            .alert("确认删除", isPresented: $showDeleteOk) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task.detached {
                        RealmManager.handler { realm in
                            let messages = realm.objects(ChatMessage.self)
                            let groups = realm.objects(ChatGroup.self)
                            try? realm.write {
                                realm.delete(messages)
                                realm.delete(groups)
                            }
                        }
                    }
                    
                }
            } message: {
                Text("此操作将删除所有聊天记录和设置数据，且无法恢复。确定要继续吗？")
            }
            .sheet(item: $selectAccount) { account in
                AddOrChangeChatAccount(assistantAccount: account, isAdd: false)
                    .customPresentationCornerRadius(20)
                    .environmentObject(chatManager)
            }
            .sheet(item: $addAccount) { account in
                AddOrChangeChatAccount(assistantAccount: account, isAdd: true)
                    .customPresentationCornerRadius(20)
                    .environmentObject(chatManager)
            }
           
        
    }
    
    
}




#Preview {
    AssistantSettingsView()
}
