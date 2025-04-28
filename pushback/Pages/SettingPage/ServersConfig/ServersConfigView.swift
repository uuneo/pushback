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
    
    
    var body: some View {
      
            List{
                Section{
                    ForEach(servers, id: \.id){ item in
                        
                        ServerCardView( item: item){
                            Clipboard.shared.setString(item.url + "/" + item.key)
                            Toast.copy(title: String(localized: "复制 URL 和 KEY 成功"))
                        }
                        
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
                        .if( servers.count > 1){ view in
                            view
                                .swipeActions(edge: .trailing, allowsFullSwipe: true){
                                    
                                    
                                    Button{
                                        if let index = servers.firstIndex(where:{$0.id == item.id}){
                                            servers.remove(at: index)
                                        }
                                    }label:{
                                        Text("移除")
                                            .fontWeight(.bold)
                                    }.tint(.red)
                                }
                        }
                        
                        
                        
                        
                    }
                    .onMove(perform: { indices, newOffset in
                        servers.move(fromOffsets: indices, toOffset: newOffset)
                    })
                }header:{
                    Label("使用中的服务器", systemImage: "cup.and.heat.waves")
                        .foregroundStyle(.primary, .green)
                }
                
                
                
                
                Section{
                    
                    
                    ForEach(cloudDatas, id: \.id){ item in
                        
                        if !servers.contains(where: { $0.url == item.url && $0.key == item.key }){
                            ServerCardView(item: item,isCloud: true){
                                manager.appendServer(server: item) { _, _ in }
                            }
                            
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
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }header: {
                    HStack{
                        Label("历史服务器", systemImage: "cup.and.heat.waves")
                            .foregroundStyle(.primary, .gray)
                        Spacer()
                        Text("\(self.cloudDatas.count)")
                    }
                }
                
            }
            .animation(.easeInOut, value: servers)
            .listRowSpacing(10)
           
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
            .navigationTitle( "服务器")
            .onAppear{ updateCloudServers() }
            
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
    
    
    
}

#Preview {
    ServersConfigView()
        .environmentObject(PushbackManager.shared)
}



