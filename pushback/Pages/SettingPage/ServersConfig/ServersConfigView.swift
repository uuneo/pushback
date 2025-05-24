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
    @Default(.cloudServers) var cloudServers
    @EnvironmentObject private var manager:AppManager
    
    
    var showClose:Bool = false
    
    
    var body: some View {
      
            List{
                Section{
                    ForEach(servers, id: \.id){ item in
                        
                        ServerCardView( item: item){
                            Clipboard.set(item.url + "/" + item.key)
                            Toast.copy(title: "复制 URL 和 KEY 成功")
                        }
                        
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button{
                                Task{
                                    let success = await manager.appendServer(server: PushServerModel(url: item.url ))
                                    
                                    if success {
                                        if let index = servers.firstIndex(where:{$0.id == item.id}){
                                            servers.remove(at: index)
                                            Task{
                                               _ = await manager.register(server: item, reset: true)
                                            }
                                        }
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
                                            Task{
                                                _ = await manager.register(server: item, reset: true)
                                            }
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
                    HStack{
                        Label("使用中的服务器", systemImage: "cup.and.heat.waves")
                            .foregroundStyle(.primary, .green)
                        Spacer()
                        Text("\(servers.count)")
                    }
                   
                }
                
                
                Section{
                    
                    ForEach(cloudServers, id: \.id){ item in
                        
                        if !servers.contains(where: { $0.url == item.url && $0.key == item.key }){
                            ServerCardView(item: item,isCloud: true){
                                servers.append(item)
                                Task{
                                    _ = await manager.register(server: item)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive){
                                    if let index = cloudServers.firstIndex(where: {$0.id == item.id}){
                                        cloudServers.remove(at: index)
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
                        Text("\(cloudServers.count - servers.count)")
                    }
                }
                
            }
            .animation(.easeInOut, value: servers)
            .listRowSpacing(10)
           
            .refreshable {
                // MARK: - 刷新策略
                manager.registers()
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
            
    }
     
}

#Preview {
    ServersConfigView()
        .environmentObject(AppManager.shared)
}



