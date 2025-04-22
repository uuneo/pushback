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
    @EnvironmentObject private var manager:PushbackManager
    @Default(.showGroup) private var showGroup
    @State private var showAction = false
    @StateObject private var groupModel = GroupMessagesModel()
    
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
                            manager.messagePath = [.example]
                            manager.allPath = [.example]
                        })
                }
                
                
                ToolbarItem {
                    
                    
                    
                    if ISPAD{
                        Menu {
                            ForEach( MessageAction.allCases, id: \.self){ item in
                                Button{
                                    deleteMessage(item)
                                }label:{
                                    Label(item.localized, systemImage: (item == .cancel ? "arrow.uturn.right.circle" : item == .markRead ? "text.badge.checkmark" : "xmark.bin.circle"))
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
                        
                        Button{
                            self.showAction = true
                        }label: {
                            Image(systemName: "trash.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.primary)
                                .symbolEffect(delay: 0)
                            
                        }
                        
                        
                    }
                    
                }
                
                
            }
            .actionSheet(isPresented: $showAction) {
                
                ActionSheet(title: Text( "删除以下时间的信息!"),
                            buttons: MessageAction.allCases.map({ item in
                    
                    switch item{
                    case .cancel:
                        Alert.Button.cancel()
                    case .markRead:
                        Alert.Button.default(Text(item.localized), action: {
                            deleteMessage(item)
                        })
                    default:
                        Alert.Button.destructive(Text(item.localized), action: {
                            deleteMessage(item)
                        })
                    }
                    
                }))
            }


    }

    
   
    
    func deleteMessage(_ mode: MessageAction){
        switch mode {
        case .markRead:
            autoreleasepool {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({ !$0.read})
                    proxy.writeAsync {
                        datas.setValue(true, forKey: "read")
                    }
                }
            }
        case .cancel:
            break
        default:
            autoreleasepool {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({ $0.createDate < mode.date })
                    proxy.writeAsync {
                        proxy.delete(datas)
                    }
                }
            }
        }
        
        Toast.success(title: String(localized: "操作成功"))
        
    }
    
  
    
}

#Preview {
    MessagePage()
}
