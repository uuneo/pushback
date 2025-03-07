//
//  SingleMessagesView.swift
//  pushback
//
//  Created by lynn on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults

struct SingleMessagesView: View {
    
    @ObservedResults(Message.self,sortDescriptor: SortDescriptor(keyPath: \Message.createDate, ascending: false)) var messages
    @Default(.images) var images
    @State private var imageDetail:ImageModel?
    @State private var currentPage: Int = 1
    @State private var itemsPerPage: Int = 50 // 每页加载50条数据
    @State private var isLoading: Bool = false
    @State private var selectMessage:Message?
    @State private var selectUserInfo:Message?
    @State private var selectMarkdown:Message?
    
    @State private var searchText:String = ""
    @State private var showAllTTL:Bool = false
    
    @ObservedResults(ChatMessage.self, sortDescriptor: .init(keyPath: \ChatGroup.timestamp)) var chatMessages
    
    var chatHomeMessage:Message{
        return ChatMessage.getAssistant(chat: chatMessages.last)
    }
    
    var body: some View {
        List{

            if searchText.isEmpty{
                
                NavigationLink{
                    AssistantPageView()
                        .navigationBarBackButtonHidden()
                        .toolbar(.hidden, for: .tabBar)
                    
                }label: {
                    MessageRow(message: chatHomeMessage, unreadCount: 0, customIcon: "chatgpt")
                }
                
                
                ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                    
                    MessageCard(message: message, searchText: searchText,showAllTTL: showAllTTL){ mode in
                        
                        switch mode{
                        case .image:
                            if let imageUrl = message.image{
                                Task{
                                    if let _ = await ImageManager.downloadImage(imageUrl),
                                       let imageModel = images.first(where: { $0.url == imageUrl}){
                                        DispatchQueue.main.async{
                                            withAnimation(.easeInOut) {
                                                self.imageDetail = imageModel
                                            }
                                        }
                                        
                                    }
                                    
                                }
                            }
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
            }else{
                SearchMessageView(searchText: searchText, group:  "")
            }
            
        }
        .overlay { showImageDetail() }
        .overlay{ showSelectMessage() }
        .overlay{ showSelectUserInfo() }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        .task {
            if let realm = try? Realm(), realm.objects(Message.self).where({ !$0.read}).count > 0 {
                RealmManager.shared.read()
            }
        }
    }
    
    @ViewBuilder
    func showImageDetail()-> some View{
        if let imageDetail {
            ImageDetailView(image: imageDetail,imageUrl: $imageDetail )
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
                .transition(.opacity)
                .navigationBarHidden(true)
                .toolbar(.hidden, for: .tabBar)
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
                            
                            Text(message.body ?? "")
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
