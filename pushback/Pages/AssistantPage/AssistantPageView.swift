//
//  AssistantPageView.swift
//  pushback
//
//  Created by uuneo on 2025/3/5.
//

import SwiftUI
import RealmSwift
import Defaults
import Combine


struct AssistantPageView:View {
    
    @Default(.assistantAccouns) var assistantAccouns
    @EnvironmentObject private var chatManager:openChatManager
    @EnvironmentObject private var manager:PushbackManager
    
    @State private var inputText:String = ""
    
    @FocusState private var isInputActive: Bool
    
    @State private var showMenu: Bool = false
    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true
    
    @State private var showChangeGroupName:Bool = false
    
    @ObservedResults(ChatGroup.self, where: (\.current)) var chatgroups
    @Default(.historyMessageBool) var historyMessageBool
    @State private var showSettings:Bool = false
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetHistory:CGFloat = 0
    @State private var rotation:Double = 0
    
    
    var body: some View {

            VStack {
                if  chatgroups.count != 0 || chatManager.isLoading {
                    
                    ChatMessageListView( chatGroup: chatgroups.first)
                    .onTapGesture {
                        PushbackManager.hideKeyboard()
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
                        PushbackManager.hideKeyboard()
                    }
                }
                
                
                
                
                Spacer()
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
                                PushbackManager.vibration(style: .heavy)
                                self.showMenu.toggle()
                            }else if value.translation.height > 100 {
                                PushbackManager.hideKeyboard()
                            }
                            
                        })
                )
                
            }
            .overlay{
                RoundedRectangle(cornerRadius: ProcessInfo.processInfo.isiOSAppOnMac ? 0 : 50)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: chatManager.isLoading ? 5 : 0
                    )
                    .padding(5)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }
            .popView(isPresented: $showChangeGroupName){
                showChangeGroupName = false
            }content: {
                if let chatgroup = chatgroups.first{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        
                        RealmManager.handler{ realm in
                            if let group = realm.objects(ChatGroup.self).where({$0.id == chatgroup.id}).first{
                                realm.writeAsync {
                                    group.name = text
                                }
                            }
                        }
                    }
                }else {
                    Spacer()
                        .onAppear{
                            self.showChangeGroupName = false
                        }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack{
                    AssistantSettingsView(showClose: true)
                        .customPresentationCornerRadius(20) 
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem {
                    Button{
                        withAnimation {
                            self.showMenu = false
                            self.showSettings.toggle()
                        }
                    }label: {
                        Text( "设置")
                    }
                }
                
                navigationToolbarContent
                
                principalToolbarContent
                
            }
            .sheet(isPresented: $showMenu) {
                SideBarMenuView(showMenu: $showMenu, showSettings: $showSettings)
                    .onChange(of: showMenu) { value in
                        DispatchQueue.main.async {
                            PushbackManager.hideKeyboard()
                        }
                    }
                    .customPresentationCornerRadius(20)
            }
            .onAppear{
                PushbackManager.vibration(style: .heavy,custom: true)
            }
            .environmentObject(chatManager)
            

    }
    
    
    private var principalToolbarContent: some ToolbarContent {
        
        ToolbarItem(placement: .principal) {
            if  chatManager.isLoading{
                StreamingLoadingView()
                    .transition(.scale)
            }else{
                
                
                if let chatGroup = chatgroups.first{
                    Menu {
                        
                        Button {
                            PushbackManager.vibration(style: .heavy)
                            self.showMenu.toggle()
                        }label: {
                            Label("对话列表", systemImage: "chevron.up")
                                .foregroundStyle(Color.primary)
                                .font(.system(size: 12))
                                .fontWeight(.bold)
                        }
                        
                        
                        Button{
                            chatManager.cancellableRequest?.cancelRequest()
                            Task.detached {
                                RealmManager.handler { realm in
                                    let groups = realm.objects(ChatGroup.self)
                                    try? realm.write {
                                        groups.setValue(false, forKey: "current")
                                    }
                                }
                            }
                            
                        }label: {
                            
                            Label("新对话", systemImage:  "rectangle.3.group.bubble")
                                .foregroundStyle(Color.primary)
                                .font(.system(size: 12))
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
                        PushbackManager.vibration(style: .heavy)
                    }
                }
                
            }
            
        }
        
    }
    
    private var navigationToolbarContent: some ToolbarContent{
        ToolbarItem(placement: .navigation) {
            Button{
                manager.allPath = []
                manager.messagePath = []
                PushbackManager.vibration(style: .heavy)
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
                        if !chatManager.isLoading{
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
            self.showSettings = true
            return
        }
        
        
        if !text.isEmpty {
           
            
            DispatchQueue.main.async{
                chatManager.currentMessageId = UUID().uuidString
                chatManager.isLoading = true
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
                            if await manager.allPath.last == .assistant{
                                PushbackManager.vibration(style: .light)
                            }
                        }
                    }
                    
                case .failure(let error):
                    //Handle chunk error here
                    Log.error(error)
                    Toast.error(title: String(localized:"发生错误\(error.localizedDescription)"))
                }
            } completion: {  error in
                
                PushbackManager.vibration(style: .heavy,custom: true)
                
                
                //Handle streaming error                                                          ,here
                if let error{
                    Toast.error(title: String(localized:"发生错误\(error.localizedDescription)"))
                    Log.error(error)
                    DispatchQueue.main.async{
                            chatManager.isLoading = false
                            chatManager.currentRequest = ""
                            chatManager.currentContent = ""
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    
                    RealmManager.handler { realm in
                       
                        let group:ChatGroup = {
                            guard let group = realm.objects(ChatGroup.self).where( {$0.current} ).first else {
                                let group2 = ChatGroup()
                                group2.current = true
                                group2.name = chatManager.currentRequest
                                if let messageId = chatManager.messageId{
                                    group2.id = messageId
                                }
                                return group2
                            }
                            return group
                        }()
                        
                      
                        
                        let responseMessage = chatManager.currentChatMessage
                        responseMessage.chat = group.id
                        
                        let groupCount = realm.objects(ChatGroup.self).where( {$0.current} ).count
                        
                        realm.writeAsync {
                            if groupCount == 0{
                                realm.add(group)
                            }
                            realm.add(responseMessage)
                        }
                       
                        chatManager.currentRequest = ""
                        chatManager.isLoading = false
                        PushbackManager.hideKeyboard()
                    }
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
                .font(.system(.subheadline))
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

struct AssistantRowView: View {
    
    @ObservedResults(ChatMessage.self, sortDescriptor: .init(keyPath: \ChatGroup.timestamp)) var chatMessages
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
        MessageRow(message: chatHomeMessage, unreadCount: 0, customIcon: "chatgpt")
            .pressEvents(onRelease: { value in
                manager.messagePath = [.assistant]
                manager.allPath = [.assistant]
            })
    }
}
