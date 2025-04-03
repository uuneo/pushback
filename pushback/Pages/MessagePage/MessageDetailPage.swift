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
    @State private var searchText:String = ""
    
   
    var group:String?
    
    init(group: String? = nil) {
        
        if let group = group {
            self.group = group
            self._messages = ObservedResults(Message.self, where: { $0.group == group }, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
        }else{
            self._messages = ObservedResults(Message.self, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
        }
        
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
            if searchText.isEmpty{
                ScrollViewReader{ proxy in
                    List{
                        ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                            
                            MessageCard(message: message, searchText: searchText,showAllTTL: showAllTTL,showAvatar: showMessageAvatar,showAssistant:showAssistant){ mode in
                                
                                switch mode{
                                case .text:
                                    withAnimation(.easeInOut) {
                                        self.selectMessage = message
                                    }
                                case .userInfo:
                                    withAnimation(.easeInOut) {
                                        self.selectUserInfo = message
                                    }
                                }
                            }
                            
                            .onAppear{
                                if messages.prefix(currentPage * itemsPerPage).last == message{
                                    
                                    currentPage = min(Int(ceil(Double(messages.count) / Double(itemsPerPage))), currentPage + 1)
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listSectionSeparator(.visible)
                            .id(message.id)
                            
                        }.onDelete(perform: $messages.remove)
                           
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
                    SearchMessageView(searchText: searchText, group: group ?? "")
                }
            }
        }
        .navigationBarHidden(navHi)
        .overlay{ showSelectMessage() }
        .overlay{ showSelectUserInfo() }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
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
        .onChange(of: messages.count){ newValue in
            if newValue == 0{
                self.dismiss()
            }
        }
        .task {
            
            if let group = group{
                if let realm = try? Realm(), realm.objects(Message.self).where({$0.group == group && !$0.read}).count > 0 {
                    RealmManager.shared.read( group)
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
    
    @ViewBuilder
    func showSelectUserInfo()-> some View{
        if let message = selectUserInfo{
            ScrollView{
                ZStack{
                    Text(message.userInfo)
                        .textSelection(.enabled)
                        .padding()
                }
                
                .frame(width: UIScreen.main.bounds.width)
                .padding(.vertical, 50)
                .frame(minHeight: UIScreen.main.bounds.height - 100)
                
                
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
            .background(.ultraThinMaterial)
            .containerShape(RoundedRectangle(cornerRadius: 0))
            .onTapGesture {
                withAnimation(.easeInOut)  {
                    self.selectUserInfo = nil
                }
            }
            .transition(.opacity)
        }else{
            Spacer()
                .onAppear{
                    self.selectUserInfo = nil
                }
        }
    }
}

#Preview {
    MessageDetailPage()
}
