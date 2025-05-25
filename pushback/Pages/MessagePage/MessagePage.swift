//
//  MessagePage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults
import RealmSwift

struct MessagePage: View {
    @EnvironmentObject private var manager:AppManager
    @Default(.showGroup) private var showGroup
    @State private var showAction = false
    @EnvironmentObject private var groupModel:MessagesData
    
    var body: some View {
       
            Group{
                if manager.searchText.isEmpty{
                    if showGroup{
                        GroupMessagesView()
                    }else{
                        SingleMessagesView()
                    }
                }else{
                    List{
                        SearchMessageView(searchText: manager.searchText)
                    }
                    
                }
                
                
            }
            .environmentObject(groupModel)
            .searchable(text: $manager.searchText)
            .listRowSpacing(10)
            .navigationTitle( "消息")
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
                
                
                ToolbarItem{
                    Image(systemName: "questionmark.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .symbolEffect(delay: 0)
                        .pressEvents(onRelease: { value in
                            manager.router = [.example]
                            return true
                            
                        })
                }
                
                
                ToolbarItem {
                    
                    if ISPAD{
                        Menu {
                            ForEach( MessageAction.allCases, id: \.self){ item in
                                Button(role: item == .cancel ? .destructive : .cancel){
                                    deleteMessage(item)
                                }label:{
                                    Label(item.localized, systemImage:  "xmark.bin.circle" )
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.primary)
                                }
                            }
                        } label: {
                            Image(systemName: "trash.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                        }
                        
                        
                    }else{
                        
                        Image(systemName: "trash.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .symbolEffect(delay: 0)
                            .padding(.horizontal)
                            .pressEvents(onRelease: { value in
                                self.showAction = true
                                return true
                                
                            })
                    }
                    
                }
                
            
            }
            .actionSheet(isPresented: $showAction) {
                
                ActionSheet(title: Text( "删除以下时间的信息!"),
                            buttons: MessageAction.allCases.map({ item in
                    
                    item == .cancel ?
                    Alert.Button.cancel() :
                    Alert.Button.default(Text(item.localized), action: {
                        deleteMessage(item)
                    })
                    
                }))
            }


    }

    
   
    
    func deleteMessage(_ mode: MessageAction){
        
        if mode != .cancel{
            autoreleasepool {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({ $0.createDate < mode.date })
                    proxy.writeAsync {
                        proxy.delete(datas)
                    }
                }
                Toast.success(title: "操作成功")
            }
        }
    }
    
  
    
}

#Preview {
    MessagePage()
}
