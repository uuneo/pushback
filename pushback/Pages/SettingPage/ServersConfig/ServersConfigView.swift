//
//  ServersConfiView.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//

import SwiftUI
import Defaults

struct ServersConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Default(.servers) var servers
    @EnvironmentObject private var manager:PushbackManager
    
    @State private var showAction:Bool = false
    @State private var serverText:String = ""
    @State private var serverName:String = ""
    @State private var pickerSelect:requestHeader = .https

    @State private var cloudDatas:[PushServerModel] = []
    @FocusState private var serverNameFocus
    
    
    var showClose:Bool = false
    var filteredCloudDatas:[PushServerModel]{
        self.cloudDatas.filter { item in
            // 筛选不在本地服务器列表中的云服务器
            !servers.contains(where: { $0.url == item.url && $0.key == item.key })
        }
    }
    
    @Default(.deviceToken) var deviceToken
    
    @State private var showTextAnimation:Bool = false
    
    var body: some View {
        NavigationStack{
            List{
                
                Section(header:Text( "设备推送令牌")) {
                    Button{
                        if deviceToken != ""{
                            Clipboard.shared.setString(deviceToken)
                            Toast.copy(title: String(localized: "复制成功"))
                            
                        }else{
                            
                            Toast.shared.present(title:  String(localized: "请先注册"), symbol: "questionmark.circle.dashed")
                        }
                        self.showTextAnimation.toggle()
                    }label: {
                        HStack{
                            
                            Label {
                                Text( "令牌")
                                    .lineLimit(1)
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "key")
                                    .scaleEffect(0.9)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.primary, .tint)
                            }
                            
                            
                            Spacer()
                            HackerTextView(text: maskString(deviceToken), trigger:showTextAnimation)
                                .foregroundStyle(.gray)
                                
                            Image(systemName: "doc.on.doc")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle( .tint, Color.primary)
                                .scaleEffect(0.9)
                        }
                    }
                }
                
                
                Section{
                    ForEach(servers, id: \.id){ item in
                        
                        ServerCardView( item: item){ index in
                            if index == 1{
                                Clipboard.shared.setString(item.url + "/" + item.key)
                                Toast.copy(title: String(localized: "复制 URL 和 KEY 成功"))
                            }else {
                                Clipboard.shared.setString(item.key)
                                Toast.copy(title: String(localized: "复制 KEY 成功"))
                            }
                        }
                        .padding(.vertical,5)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button{
                                manager.appendServer(server: PushServerModel(url: item.url )) { success, msg in
                                    if success{
                                        manager.register(server: item, reset: true)
                                        if let index = servers.firstIndex(where: {$0.id == item.id}){
                                            servers.remove(at: index)
                                            if  !cloudDatas.contains(where: { $0.id == item.id}){
                                                cloudDatas.insert(item, at: 0)
                                            }
                                        }
                                        Toast.success(title: String(localized: "操作成功"))
                                        
                                    }else {
                                        Toast.info(title: String(localized: "操作失败"))
                                    }
                                    
                                }
                                
                            }label:{
                                Text("重置")
                                    .fontWeight(.bold)
                            }.tint(.accentColor)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true){
                            
                            
                            Button{
                                
                                if servers.count > 1{
                                    if let index = servers.firstIndex(where:{$0.id == item.id}){
                                        servers.remove(at: index)
                                    }
                                }else{
                                    Toast.error(title:String(localized: "必须保留一个服务"))
                                }
                            }label:{
                                Text("移除")
                                    .fontWeight(.bold)
                            }.tint(.red)
                        }
                        
                        
                        
                    }
                    .onMove(perform: { indices, newOffset in
                        servers.move(fromOffsets: indices, toOffset: newOffset)
                    })
                }header:{
                    Text("使用中的服务器")
                }
                
                
                
                if filteredCloudDatas.count > 0{
                    Section{
                        
                        
                        ForEach(filteredCloudDatas, id: \.id){ item in
                            
                            ServerCardView(item: item,isCloud: true){ _ in
                                manager.appendServer(server: item) { _, _ in }
                            }
                            .padding(.vertical,5)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive){
                                    PushServerCloudKit.shared.deleteCloudServer(item.id) { err in
                                        if let err{
                                            Log.debug(err.localizedDescription)
                                        }else{
                                            if let index = cloudDatas.firstIndex(where: {$0.id == item.id}){
                                                cloudDatas.remove(at: index)
                                            }
                                            
                                        }
                                        
                                    }
                                }label:{
                                    Label("删除", systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.primary, Color.accentColor)
                                }
                            }
                            
                            
                        }
                    }header: {
                        HStack{
                            
                            Text("历史服务器")
                            Spacer()
                            Text("\(self.cloudDatas.count)")
                        }
                    }
                    .transaction { view in
                        view.animation = .easeInOut
                    }
                }
                
                
                
            }
            .animation(.easeInOut, value: servers)
            .listRowSpacing(20)
            .refreshable {
                // MARK: - 刷新策略
                await manager.registers(){ result in
                    Toast.info(title: String(localized: "操作成功"))
                    
                }
                
                updateCloudServers()
            }
            
            .toolbar{
                
                
                
                ToolbarItem {
                    withAnimation {
                        Button{
                            manager.fullPage = .customKey
                            manager.sheetPage = .none
                        }label:{
                            Image(systemName: "externaldrive.badge.plus")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle( Color.accentColor,Color.primary)
                        }
                    }
                    
                }
                
                
                if showClose {
                    
                    ToolbarItem{
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.seal")
                        }
                        
                    }
                }
            }
            .navigationTitle( "令牌与服务器")
            .onAppear{ updateCloudServers() }
            
        }
    }
    
    
    func updateCloudServers(){
        PushServerCloudKit.shared.fetchPushServerModels { response in
            switch response {
            case .success(let results):
                withAnimation(.easeInOut) {
                    self.cloudDatas = results
                }
            case .failure(let failure):
                Log.debug(failure.localizedDescription)
            }
        }
    }
    
    
    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 6 else { return str }
        return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(6)
    }
    
    
}

#Preview {
    ServersConfigView()
        .environmentObject(PushbackManager.shared)
}



