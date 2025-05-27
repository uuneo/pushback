//
//  AssistantPageView.swift
//  pushback
//
//  Created by uuneo on 2025/3/5.
//

import SwiftUI
import Defaults
import Combine
import GRDB


struct AssistantPageView:View {
    
    @Default(.assistantAccouns) var assistantAccouns
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var chatManager = openChatManager.shared
    @EnvironmentObject private var manager:AppManager
    
    @State private var inputText:String = ""
    
    @FocusState private var isInputActive: Bool
    
    @State private var showMenu: Bool = false
    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true
    
    @State private var showChangeGroupName:Bool = false
    
    @State private var chatgroups:[ChatGroup] = []
    @Default(.historyMessageBool) var historyMessageBool
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetHistory:CGFloat = 0
    @State private var rotation:Double = 0
    
    
    var body: some View {

            VStack {
                if  chatgroups.count != 0 || manager.isLoading {
                    
                    ChatMessageListView( chatGroup: chatgroups.first)
                    .onTapGesture {
                        AppManager.hideKeyboard()
                    }
                    
                }else{
                    VStack{
                        Spacer()
                        
                        VStack{
                            Image("chatgpt")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                            
                            Text("嗨! 我是智能助手")
                                .font(.title)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                            
                            Text("我可以帮你搜索，答疑，写作，请把你的任务交给我吧！")
                                .multilineTextAlignment(.center)
                                .padding(.vertical)
                                .font(.body)
                                .foregroundStyle(.gray)
                            
                        }
                        
                        Spacer()
                    }
                    .transition(.slide)
                    .onTapGesture {
                        AppManager.hideKeyboard()
                    }
                }
                
                
                
                
                Spacer()
               
            }
            .safeAreaInset(edge: .bottom) {
                // 底部输入框
                ChatInputView(
                    text: $inputText,
                    onSend: sendMessage,
                    onSelectedPicture: handleSelectedPicture,
                    onSelectedFile: handleSelectedFile,
                    onCapturePhoto: {}
                )
                .simultaneousGesture(
                    DragGesture()
                        .onEnded({ value in
                            Log.debug(value.translation, value.startLocation)
                            if -value.translation.height > 200{
                                AppManager.vibration(style: .heavy)
                                self.showMenu.toggle()
                            }else if value.translation.height > 100 {
                                AppManager.hideKeyboard()
                            }
                            
                        })
                )
                
            }
            .popView(isPresented: $showChangeGroupName){
                showChangeGroupName = false
            }content: {
                if let chatgroup = chatgroups.first{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        chatManager.updateGroupName(groupId: chatgroup.id, newName: text)
                    }
                }else {
                    Spacer()
                        .onAppear{
                            self.showChangeGroupName = false
                        }
                }
            }
            .toolbar {
                
                ToolbarItem {
                    Label("设置", systemImage: "gear")
                        .foregroundStyle(.accent)
                        .pressEvents(onRelease: { _ in
                            withAnimation {
                                manager.router.append(.assistantSetting(nil))
                            }
                            return true
                        })
                }
                
                navigationToolbarContent
                
                principalToolbarContent
                
            }
            .sheet(isPresented: $showMenu) {
                SideBarMenuView(showMenu: $showMenu)
                    .onChange(of: showMenu) { value in
                        DispatchQueue.main.async {
                            AppManager.hideKeyboard()
                        }
                    }
                    .customPresentationCornerRadius(20)
            }
            .onAppear{
                manager.inAssistant = true
            }
            .environmentObject(chatManager)
            .onDisappear{
                manager.askMessageId = nil
                manager.inAssistant = false
            }

    }
    
    
    private var principalToolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .principal) {
            if  manager.isLoading{
                StreamingLoadingView()
                    .transition(.scale)
            }else{
                
                
                if let chatGroup = chatgroups.first{
                    Menu {
                        
                        Button {
                            AppManager.vibration(style: .heavy)
                            self.showMenu.toggle()
                        }label: {
                            Label("对话列表", systemImage: "chevron.up")
                                .foregroundStyle(Color.primary)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        
                        Button{
                            chatManager.cancellableRequest?.cancelRequest()
                            Task.detached {
                                try await chatManager.dbQueue.write { db in
                                    // 使用 SQL 语句执行批量更新
                                    try db.execute(sql: "UPDATE chatGroup SET current = 0")
                                }
                            }
                            
                        }label: {
                            
                            Label("新对话", systemImage:  "rectangle.3.group.bubble")
                                .foregroundStyle(Color.primary)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        Section{
                            Button(role: .destructive){
                                self.showChangeGroupName.toggle()
                            }label: {
                                Label("重命名", systemImage: "eraser.line.dashed")
                            }
                        }
                        
                        
                    } label: {
                        
                        HStack{
                            
                            Text(chatGroup.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.trailing, 3)
                            
                            Image(systemName: "chevron.down")
                                .imageScale(.large)
                                .foregroundStyle(.gray.opacity(0.5))
                                .imageScale(.small)
                            
                            Spacer()
                            
                        }
                        .frame(maxWidth: 150)
                        .foregroundStyle(.foreground)
                        .transition(.scale)
                        
                        
                        
                    }
                    
                }else {
                    HStack{
                        
                        
                        Text( "新对话")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.trailing, 3)
                        
                        Image(systemName: "chevron.down")
                            .imageScale(.large)
                            .foregroundStyle(.gray.opacity(0.5))
                            .imageScale(.small)
                        
                    }
                    .frame(maxWidth: 150)
                    .foregroundStyle(.foreground)
                    .transition(.scale)
                    .onTapGesture {
                        self.showMenu = true
                        AppManager.vibration(style: .heavy)
                    }
                }
                
            }
            
        }
        
    }
    
    private var navigationToolbarContent: some ToolbarContent{
        ToolbarItem(placement: .navigation) {
            Button{
                manager.inAssistant = false
                manager.router.removeAll(where: {$0 == .assistant})
                AppManager.vibration(style: .heavy)
            }label: {
                Image(systemName: "arrow.left")
                
            } .tint(.gray)
        }
        
        
    }
    
    private var hideToolbarContent: some ToolbarContent{
        ToolbarItem {
            HStack{
                
                Button{
                    withAnimation {
                        if !manager.isLoading{
                            chatManager.currentRequest = ""
                            chatManager.currentContent = ""
                        }
                        
                    }
                }label: {
                    Text( "隐藏")
                    
                }
                
            }
            
        }
    }
    
    
    // 发送消息
    private  func sendMessage(_ text: String) {
        guard assistantAccouns.first(where: {$0.current}) != nil else {
            return
        }
        
        
        if !text.isEmpty {
           
            
            DispatchQueue.main.async{
                chatManager.currentMessageId = UUID().uuidString
                manager.isLoading = true
                chatManager.currentRequest = text
                
                self.inputText = ""
                chatManager.currentContent = ""
            }
            
            chatManager.chatsStream(text: text) { partialResult in
                switch partialResult {
                case .success(let result):
                   
                    if let res = result.choices.first?.delta.content {
                        
                        DispatchQueue.main.async{
                            chatManager.currentContent = chatManager.currentContent + res
                        }
                        
                        Task{
                            if await manager.inAssistant {
                                AppManager.vibration(style: .light)
                            }
                        }
                    }
                    
                case .failure(let error):
                    //Handle chunk error here
                    Log.error(error)
                    Toast.error(title: "发生错误\(error.localizedDescription)")
                }
            } completion: {  error in
                
                AppManager.vibration(style: .heavy,custom: true)
                
                //Handle streaming error                                                          ,here
                if let error{
                    Toast.error(title: "发生错误\(error.localizedDescription)")
                    Log.error(error)
                    DispatchQueue.main.async{
                        manager.isLoading = false
                        chatManager.currentRequest = ""
                        chatManager.currentContent = ""
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    let group:ChatGroup = {
                        if let group = try? chatManager.dbQueue.read ({ db in
                            try? ChatGroup.filter(Column("current") == true).fetchOne(db)
                        }){
                            return group
                        }
                        
                        return ChatGroup(id: manager.askMessageId ?? UUID().uuidString,timestamp: .now,name: chatManager.currentRequest, host: "", current: true)
                    }()
                    
                  
                    
                    var responseMessage = chatManager.currentChatMessage
                    responseMessage.chat = group.id
                    
                    try? chatManager.dbQueue.write { db in
                        let groupCount = try ChatGroup.filter(Column("current") == true).fetchCount(db)
                        
                        if groupCount == 0 {
                            try group.insert(db)
                        }
                        
                        try responseMessage.insert(db)
                    }
                    
                    chatManager.currentRequest = ""
                    manager.isLoading = false
                    AppManager.hideKeyboard()
                }
                

            }
            
        }
    }
    
    
    
    
    func handlePause() {
        Log.debug("handlePause")
    }
    
    func handleSelectedPicture() {
        Log.debug("selectedPicture")
    }
    
    func handleSelectedFile() {
        Log.debug("selectedFile")
    }
    
}

struct CustomAlertWithTextField: View {
    @State private var text: String = ""
    @Binding var show: Bool
    var confirm: (String) -> ()
    /// View Properties
    ///
    init(_ show: Binding<Bool>, text: String, confirm: @escaping (String) -> Void) {
        self.text = text
        self._show = show
        self.confirm = confirm
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 65, height: 65)
                .background {
                    Circle()
                        .fill(.blue.gradient)
                        .background {
                            Circle()
                                .fill(.background)
                                .padding(-5)
                        }
                }
            
            Text("修改分组名称")
                .fontWeight(.semibold)
            
            Text("此名称用来查找历史分组使用")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top, 5)
            
            
            
            TextField("输入分组名称", text: $text, axis: .vertical)
                .frame(maxHeight: 150)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.bar)
                }
                .padding(.vertical, 10)
            
            HStack(spacing: 10) {
                Button {
                    show = false
                } label: {
                    Text("取消")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red.gradient)
                        }
                }
                
                Button {
                    show = false
                    confirm(text)
                } label: {
                    Text("确认")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.gradient)
                        }
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .padding([.horizontal, .bottom], 20)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.background)
                .padding(.top, 25)
        }
    }
}

struct StreamingLoadingView: View {
    @EnvironmentObject private var chatManager:openChatManager
    @State private var dots = ""
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    var body: some View {
        HStack(spacing: 4) {
            // AI头像或图标
            Image(systemName: "brain")
                .foregroundColor(.blue)
                .imageScale(.medium)
            
            // 思考中的动画点
            Text((chatManager.currentContent.isEmpty ?  "思考中" : "正在输入") + "\(dots)")
                .foregroundColor(.secondary)
                .font(.subheadline)
                .animation(.bouncy, value: dots)
        }
        .onAppear {
            self.timerCancellable = self.timer.connect()
        }
        .onDisappear {
            self.timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}

