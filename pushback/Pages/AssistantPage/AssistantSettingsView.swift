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
    @StateObject private var chatManager = openChatManager.shared
    
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.historyMessageCount) var historyMessageCount
    @Default(.showCodeViewColor) var showCodeViewColor
    @Default(.showAssistant) var showAssistant
    
    @State private var showDeleteOk:Bool = false
    @State private var isSecured = true
    @State private var isTestingAPI = false
    @State private var selectAccount:AssistantAccount? = nil
    
    var showClose:Bool
    
    
    var body: some View {

            List{
                
                Section{
                    Toggle(isOn: $showAssistant) {
                        Label("开启智能助手", systemImage:  showAssistant ? "sharedwithyou" : "sharedwithyou.slash")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .symbolEffect(.replace)
                        
                    }
                }
                
                if showAssistant{
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
                                            .font(.system(size: 15))
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
                                            .font(.system(size: 12))
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
                                    PushbackManager.vibration(style: .heavy)
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
                
               
            }
            .navigationTitle(showClose ? "设置" : "智能助手")
            .toolbar {
                if showClose{
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            withAnimation {
                                self.dismiss()
                            }
                        }label: {
                            Image(systemName: "xmark")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, .primary)
                        }
                    }
                }
               
            }
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
                ChangeChatAccount(assistantAccount: account)
                    .customPresentationCornerRadius(20)
                    .environmentObject(chatManager)
            }
           
        
    }
    
    
}

struct ChangeChatAccount:View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatManager:openChatManager
    @State private var data: AssistantAccount
    @Default(.assistantAccouns) var assistantAccouns
    @State private var isSecured:Bool = true
    @State private var isTestingAPI = false
    
    var title:String
    
    @State private var buttonState:AnimatedButton.buttonState = .normal
    
    init(assistantAccount: AssistantAccount) {
        self._data = State(wrappedValue: assistantAccount)
        if assistantAccount.key.isEmpty{
            self.title = String(localized: "增加新资料")
        }else{
            self.title = String(localized: "修改资料")
        }
    }
    
    var body: some View {
        NavigationStack{
            List{
                
                Section("输入别名") {
                    baseNameField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("请求地址(api.openai.com)") {
                    baseHostField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                Section("请求路径: /v1") {
                    basePathField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("模型名称: (gpt-4o-mini)") {
                    baseModelField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                Section("请求密钥") {
                    apiKeyField
                }
                .textCase(.none)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSpacing(0)
                
                
                Section{
                    HStack{
                        Spacer()
                        AnimatedButton(state:$buttonState, normal:
                                .init(title: String(localized: "测试连接"),background: .blue,symbolImage: "person.crop.square.filled.and.at.rectangle"), success:
                                .init(title: String(localized: "连接成功"), background: .green,symbolImage: "checkmark.circle"), fail:
                                .init(title: String(localized: "连接失败"),background: .red,symbolImage: "xmark.circle"), loadings: [
                                    .init(title: String(localized: "测试中..."), background: .cyan)
                                ]) { view in
                                    await view.next(.loading(1))
                                    
                                    data.trimAssistantAccountParameters()
                                    
                                    if data.key.isEmpty || data.host.isEmpty || isTestingAPI{
                                        try? await Task.sleep(for: .seconds(1))
                                        await view.next(.fail)
                                        return
                                    }
                                    
                                    self.isTestingAPI = true
                                    chatManager.test(account: data) { success in
                                        Task{
                                            await view.next(success ? .success : .fail)
                                            DispatchQueue.main.async{
                                                self.isTestingAPI = false
                                            }
                                        }
                                    }
                                    
                                }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                
            }
           
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.dismiss()
                    } label: {
                        Text("取消")
                    }.tint(.red)
                        .disabled(isTestingAPI)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    
                        self.saveOrChangeData()
                        
                    } label: {
                        Text("保存")
                    }
                    .disabled(isTestingAPI)
                }
            }
            .disabled(isTestingAPI)
        }
    }
    
    private func saveOrChangeData(){
        data.trimAssistantAccountParameters()
       
        if data.host.isEmpty || data.key.isEmpty || data.model.isEmpty {
            Toast.info(title: String(localized:"参数不能为空"))
            return
        }
        
        if assistantAccouns.count == 0{
            data.current = true
        }
        
        
        if let index = assistantAccouns.firstIndex(where: {$0.id == data.id}){
            
            assistantAccouns[index] = data
            Toast.success(title: String(localized:"添加成功"))
            self.dismiss()
            return
        }else{
            
            
            if assistantAccouns.filter({$0.host == data.host && $0.basePath == data.basePath && $0.model == data.model && $0.key == data.key}).count > 0 {
                Toast.error(title: String(localized:"重复数据"))
                return
            }
            
            assistantAccouns.insert(data, at: 0)
            Toast.success(title:String(localized: "修改成功"))
            self.dismiss()
        }
        
        
       
        
    }
    
    private var apiKeyField: some View {
        HStack {
            if isSecured {
                SecureField("API Key", text: $data.key)
                    .textContentType(.password)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            } else {
                TextField("API Key", text: $data.key)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .customField(
                        icon: "key.icloud"
                    )
            }
            
            Image(systemName: isSecured ? "eye.slash" : "eye")
                .foregroundColor(isSecured ? .gray : .primary)
                .onTapGesture {
                    isSecured.toggle()
                }
        }
    }
    
    private var baseNameField: some View {
        TextField("Name", text: $data.name)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "atom"
            )
    }
    
    private var baseHostField: some View {
        TextField("Host", text: $data.host)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "network"
            )
    }
    
    private var basePathField: some View {
        TextField("BasePath", text: $data.basePath)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(
                icon: "point.filled.topleft.down.curvedto.point.bottomright.up"
            )
    }
    
    private var baseModelField: some View {
        TextField("Model", text: $data.model)
            .autocapitalization(.none)
            .keyboardType(.URL)
            .customField(icon: "slider.horizontal.2.square.badge.arrow.down")
    }
    
  
}




#Preview {
    AssistantSettingsView(showClose: false)
}
