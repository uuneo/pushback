//
//  MessageDetailPage.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct MessageDetailPage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var manager:PushbackManager
    
    @ObservedResults(Message.self) var messages
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.showAssistant) var showAssistant
    
   
    var group:String?
    
    init(group: String) {
        
        self.group = group
        self._messages = ObservedResults(Message.self, where: { $0.group == group }, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
        
    }
    
    
    // 分页相关状态
    @State private var currentPage: Int = 1
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    @State private var selectMessage:Message?
    @State private var selectUserInfo:Message?
    @State private var selectMarkdown:Message?
    @State private var showAllTTL:Bool = false
    
    var navHi:Bool{
        selectMessage != nil || selectUserInfo != nil  || selectMarkdown != nil
    }
    
    
    
    
    var body: some View {
        
        Group{
            if manager.searchText.isEmpty{
                ScrollViewReader{ proxy in
                    List{
                        ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                            
                            MessageCard(message: message, searchText: manager.searchText,showAllTTL: showAllTTL,showAvatar: showMessageAvatar,showAssistant:showAssistant){
                                withAnimation(.easeInOut) {
                                    self.selectMessage = message
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.visible)
                            
                        }.onDelete(perform: $messages.remove)
                        
                        Color.clear
                            .listRowBackground(Color.clear)
                            .onAppear{
                                if !self.isLoading {
                                    isLoading = true
                                    currentPage = min(Int(ceil(Double(messages.count) / Double(itemsPerPage))), currentPage + 1)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                                        isLoading = false
                                    }
                                   
                                }
                            }
                           
                    }
                    .onAppear{
                        manager.selectGroup = nil
                        
                        if let selectId = manager.selectId{
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                withAnimation {
                                    proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    manager.selectId = nil
                                }
                            }
                        }
                    }
                    
                }
                
            }else {
                List{
                    SearchMessageView(searchText: manager.searchText, group: group)
                }
            }
        }
        .navigationBarHidden(navHi)
        .overlay{ showSelectMessage() }
        .searchable(text: $manager.searchText)
        .toolbar{
            ToolbarItem {
                Button{
                    withAnimation {
                        self.showAllTTL.toggle()
                    }
                    
                }label: {
                    Text("\(min(currentPage * itemsPerPage, messages.count))/\(messages.count)")
                        .font(.caption)
                }
            }
        }
        .task(priority: .background) {
            
            if let group = group{
                Task.detached{
                    RealmManager.handler { proxy in
                        let datas = proxy.objects(Message.self).where({$0.group == group}).where({!$0.read})
                        try? proxy.write {
                            datas.setValue(true, forKey: "read")
                        }
                    }
                }
            }
        }
        
        
    }
    @ViewBuilder
    func showSelectMessage()-> some View{
        if let message =  selectMessage{
            ScrollView{
                
                ZStack{
                    
                    VStack{
                        HStack{
                            Spacer(minLength: 0)
                            Text(message.title ?? "")
                                .font(.title3.bold())
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                        
                        HStack{
                            Spacer(minLength: 0)
                            Text(message.subtitle ?? "")
                                .font(.headline.bold())
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                        
                        Line()
                            .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
                            .frame(height: 1)
                            .padding(.horizontal, 5)
                        
                        HStack{
                            MarkdownCustomView(content: message.body ?? "", searchText: "", showCodeViewColor: false)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width - 50)
                }
                .frame(width: UIScreen.main.bounds.width)
                .padding(.vertical, 50)
                .frame(minHeight: UIScreen.main.bounds.height - 100)
                
            }
            
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .background(.ultraThinMaterial)
            .containerShape(RoundedRectangle(cornerRadius: 0))
            .onTapGesture {
                withAnimation(.easeInOut) {
                    self.selectMessage = nil
                }
            }
            
            .transition(.opacity)
        }else{
            Spacer()
                .onAppear{
                    self.selectMessage = nil
                }
        }
        
    }
}

#Preview {
    MessageDetailPage(group: "")
}
