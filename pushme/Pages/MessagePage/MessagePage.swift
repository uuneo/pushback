//
//  MessagePage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults

struct MessagePage: View {
    @EnvironmentObject private var manager:AppManager
    @Default(.showGroup) private var showGroup
    @Default(.servers) private var servers
    @StateObject private var messageManager = MessagesManager.shared
    
    var body: some View {
        
        Group{
            if manager.searchText.isEmpty{
                SingleMessagesView()
                    .if(showGroup) {
                        GroupMessagesView()
                    }
            }else{
                SearchMessageView(searchText: $manager.searchText)
            }
        }
        .navigationTitle( "消息")
        .environmentObject(messageManager)
        .searchable(text: $manager.searchText)
        .listRowSpacing(10)
        .toolbar{
            
            ToolbarItem( placement: .topBarLeading) {
                Button{
                    self.showGroup.toggle()
                    manager.selectGroup = nil
                    manager.selectId = nil
                }label:{
                    
                    Image(systemName: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .animation(.easeInOut, value: showGroup)
                        .symbolEffect(delay: 0)
                }
            }
            if servers.count > 0{
                ToolbarItem{
                    Image(systemName: "questionmark.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .symbolEffect(delay: 0)
                        .padding(.horizontal, 10)
                        .VButton(onRelease: { value in
                            manager.router = [.example]
                            return true
                            
                        })
                }
            }else{
                ToolbarItem{
                    Image(systemName: "key.viewfinder")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .symbolEffect(delay: 0)
                        .VButton(onRelease: { value in
                            manager.registerForRemoteNotifications()
                            return true
                            
                        })
                }
            }
            
            
            ToolbarItem {
                
                    Menu {
                        ForEach( MessageAction.allCases, id: \.self){ item in
                            Button(role: item == .cancel ? .destructive : .cancel){
                                deleteMessage(item)
                            }label:{
                                Label(item.localized, systemImage:  item == .cancel ? "xmark.seal" : "trash" )
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green, Color.primary)
                            }
                        }
                    } label: {
                        Image(systemName: "trash.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                    }
                    
                
            }
            
            
        }
        
        
    }
    
    
    
    
    func deleteMessage(_ mode: MessageAction){
        if mode != .cancel{
            Task.detached(priority: .userInitiated) {
                await DatabaseManager.shared.delete(date: mode.date)
            }
        }
    }
    
    
    
}

#Preview {
    MessagePage()
}
