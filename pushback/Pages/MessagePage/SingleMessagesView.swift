//
//  SingleMessagesView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct SingleMessagesView: View {
    
    @ObservedResults(Message.self,sortDescriptor: SortDescriptor(keyPath: \Message.createDate, ascending: false)) var messages
    @ObservedResults(ChatMessage.self, sortDescriptor: .init(keyPath: \ChatGroup.timestamp)) var chatMessages
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.showAssistant) var showAssistant
    
    @State private var currentPage: Int = 1
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    @State private var selectMessage:Message?
    @State private var selectUserInfo:Message?
    @State private var selectMarkdown:Message?
    
    @State private var searchText:String = ""
    @State private var showAllTTL:Bool = false
    
    @EnvironmentObject private var manager:PushbackManager
    var chatHomeMessage:Message{
        var chatGroup:ChatMessage? = nil
        
        if let realm = try? Realm(),
           let chat = realm.objects(ChatMessage.self).sorted(byKeyPath: "timestamp").last {
            chatGroup = chat
            
        }
        
        return ChatMessage.getAssistant(chat: chatGroup)
        
        
    }
    
    var body: some View {
        
        Group{
            
            if searchText.isEmpty{
                ScrollViewReader { proxy in
                    List{
                        if showAssistant{
                            MessageRow(message: chatHomeMessage, unreadCount: 0, customIcon: "chatgpt")
                                .pressEvents(onRelease: { value in
                                    manager.messagePath = [.assistant]
                                })
                        }
                    
                        ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                            
                            MessageCard(message: message, searchText: searchText,showAllTTL: showAllTTL,showAvatar:showMessageAvatar,showAssistant:showAssistant){ mode in
                                
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
                            
                        }.onDelete(perform: $messages.remove)
                            .onAppear{
                                DispatchQueue.main.async{
                                    proxyTo(proxy: proxy, selectId: manager.selectId )
                                }
                            }
                            .onChange(of: manager.selectId){ value in
                                DispatchQueue.main.async{
                                    proxyTo(proxy: proxy, selectId: value )
                                }
                            }
                    }
                }
            }else{
                List{
                    SearchMessageView(searchText: searchText, group:  "")
                }
                
                
            }
        }
        .overlay{ showSelectMessage() }
        .overlay{ showSelectUserInfo() }
        .searchable(text: $searchText, collection: $messages, keyPath: \.allString)
        .task {
            RealmManager.realm { proxy in
                let datas = proxy.objects(Message.self).filter({ !$0.read})
                for data in datas{
                    data.read = true
                }
            }
        }
    }
    
    private func proxyTo(proxy: ScrollViewProxy, selectId:String?){
        if let selectId = selectId{
            withAnimation {
                proxy.scrollTo(UUID(uuidString: selectId), anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                manager.selectId = nil
                manager.selectGroup = nil
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
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
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
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
        }else{
            Spacer()
                .onAppear{
                    self.selectUserInfo = nil
                }
        }
    }
}

#Preview {
    SingleMessagesView()
}
