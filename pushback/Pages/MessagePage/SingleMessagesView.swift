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
    
    var currentMessage:[Message]{
        Array(messages.prefix(currentPage * itemsPerPage))
    }
    
    var body: some View {
        
        Group{
            
                ScrollViewReader { proxy in
                    List{
                        if showAssistant{
                            AssistantRowView()
                        }
                    
                        ForEach(currentMessage, id: \.id) { message in
                            
                            MessageCard(message: message, searchText: manager.searchText,showAllTTL: showAllTTL,showAvatar:showMessageAvatar,showAssistant:showAssistant){
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
        .overlay{ showSelectMessage() }
        
        .task {
            Task.detached {
                RealmManager.handler { proxy in
                    let datas = proxy.objects(Message.self).where({!$0.read})
                    try? proxy.write {
                        datas.setValue(true, forKey: "read")
                    }
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
}

#Preview {
    SingleMessagesView()
}


struct BottomScrollDetector: View {
    let onBottomReached: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).maxY)
        }
        .frame(height: 0) // 不占空间
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
