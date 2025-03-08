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
    @Environment(\.dismiss) var dismiss
    @Default(.assistantAccouns) var assistantAccouns
    
    @State var messageId:String? = nil
    
    @State private var currentRequestText: String = ""
    @State private var currentContent:String = ""
    @State private var inputText:String = ""
    
    @FocusState private var isInputActive: Bool
    
    @State private var showMenu: Bool = false
    @State private var rotateWhenExpands: Bool = false
    @State private var disablesInteractions: Bool = true
    @State private var disableCorners: Bool = true
    @State private var isLoading:Bool = false
    
    @State private var showChangeGroupName:Bool = false
    
    @ObservedResults(ChatGroup.self, where: (\.current)) var chatgroups
    
    @State private var showSettings:Bool = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                if  chatgroups.count != 0 || !currentRequestText.isEmpty || messageId != nil{
                    
                    ChatMessageListView(
                        chatGroup: chatgroups.first,
                        currentRequest: currentRequestText,
                        currentContent: currentContent,
                        isLoading: isLoading,
                        messageId: messageId,
                        onEditMessage: { _ in}
                    )
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
                    isLoading: isLoading,
                    isResponding: false,
                    onSend: sendMessage,
                    onPause: handlePause,
                    onSelectedPicture: handleSelectedPicture,
                    onSelectedFile: handleSelectedFile,
                    onCapturePhoto: {}
                )
                
            }
            
            .popView(isPresented: $showChangeGroupName){
                showChangeGroupName = false
            }content: {
                if let chatgroup = chatgroups.first{
                    CustomAlertWithTextField( $showChangeGroupName, text: chatgroup.name) { text in
                        RealmManager.shared.realm { realm in
                            if let group = chatgroup.thaw(){
                                group.name = text
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
                AssistantSettingsView()
                    .customPresentationCornerRadius(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem {
                    HStack{
                        
                        Button{
                            withAnimation {
                                self.showSettings.toggle()
                            }
                        }label: {
                            Text( "设置")
                               
                        }
                        
                    }
                    
                }
                
                ToolbarItem(placement: .navigation) {
                    if isLoading{
                        StreamingLoadingView(isAwait: currentContent.isEmpty)
                            .transition(.scale)
                    }else{
                        
                        Menu {
                            
                           
                            
                            if chatgroups.count > 0{
                                
                                Section{
                                    Button(role: .destructive){
                                        self.showChangeGroupName.toggle()
                                    }label: {
                                        Label("重命名", systemImage: "eraser.line.dashed")
                                    }
                                }
                            }
                            Button {
                                PushbackManager.vibration(style: .heavy)
                                self.showMenu.toggle()
                            }label: {
                                Label("对话列表", systemImage: "chevron.up")
                                    .foregroundStyle(Color.primary)
                                    .font(.system(size: 12))
                                    .fontWeight(.bold)
                            }
                            
                            if chatgroups.count != 0{
                                Button{
                                    openChatManager.shared.cancellableRequest?.cancelRequest()
                                    
                                    RealmManager.shared.realm { realm in
                                        let groups = realm.objects(ChatGroup.self)
                                        for group in groups{
                                            group.current = false
                                        }
                                    }
                                }label: {
                                   
                                    Label("新对话", systemImage:  "rectangle.3.group.bubble")
                                        .foregroundStyle(Color.primary)
                                        .font(.system(size: 12))
                                        .fontWeight(.bold)
                                }
                            }
                            
                            
                            
                            Section{
                                Button(role: .destructive){
                                   dismiss()
                                }label: {
                                    Label("关闭", systemImage: "x.circle")
                                }
                            }
                            
                            
                        } label: {
                            
                            
                            if let chatgroup = chatgroups.first{
                                HStack{
                                    
                                    Image(systemName: "chevron.left")
                                        .imageScale(.large)
                                        .foregroundStyle(.gray)
                                        .padding(.trailing, 10)
                                    Text(chatgroup.name)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        
                                    Spacer()
                                    
                                }
                                .frame(maxWidth: 150)
                                .foregroundStyle(.foreground)
                                    .transition(.scale)
                            }else {
                                
                                HStack{
                                    
                                    Image(systemName: "chevron.left")
                                        .imageScale(.large)
                                        .foregroundStyle(.gray)
                                        .padding(.trailing, 10)
                                    Text("新对话")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        
                                    Spacer()
                                    
                                }
                                .frame(maxWidth: 150)
                                .foregroundStyle(.foreground)
                                .transition(.scale)
                                
                            }
                            
                            
                        }
                        
                    }
                    
                }
                
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
                self.currentRequestText = text
                withAnimation {
                    self.isLoading = true
                }
                self.inputText = ""
            }
            
            openChatManager.shared.chatsStream(text: text, messageId: messageId) { partialResult in
                switch partialResult {
                case .success(let result):
                    
                    if let res = result.choices.first?.delta.content {
                        currentContent = currentContent + res
                    }
                    
                case .failure(let error):
                    //Handle chunk error here
                    debugPrint(error)
                    Toast.shared.present(title: String(localized:"发生错误\(error.localizedDescription)"), symbol: .info)
                }
            } completion: {  error in
                
                //Handle streaming error here
                if let error{
                    Toast.shared.present(title: String(localized:"发生错误\(error.localizedDescription)"), symbol: .info)
                    debugPrint(error)
                    withAnimation {
                        self.isLoading = false
                    }
                    currentRequestText = ""
                    currentContent = ""
                    return
                }
                
                DispatchQueue.main.async{
                    self.isLoading = false
                    PushbackManager.hideKeyboard()
                }
                
                
                let group2 = ChatGroup()
                
                RealmManager.shared.realm { realm in
                    var group:ChatGroup{
                        guard let group = realm.objects(ChatGroup.self).where( {$0.current} ).first else {
                            group2.current = true
                            group2.name = currentRequestText
                            if let messageId{
                                group2.id = messageId
                            }
                            return group2
                        }
                        return group
                    }
                    
                    let responseMessage = ChatMessage()
                    responseMessage.request = currentRequestText
                    responseMessage.content = currentContent
                    responseMessage.chat = group.id
                    responseMessage.messageId = messageId
                    
                    if realm.objects(ChatGroup.self).where( {$0.current} ).count == 0{
                        realm.add(group)
                    }
                    realm.add(responseMessage)
                    
                    self.currentRequestText = ""
                    self.currentContent = ""
                    /// 如果是连续对话就清空id
                    if Defaults[.historyMessageBool]{
                        self.messageId = nil
                    }                }
            }
            
        }
    }
    
    
    
    
    func handlePause() {
        print("handlePause")
    }
    
    func handleSelectedPicture() {
        print("selectedPicture")
    }
    
    func handleSelectedFile() {
        print("selectedFile")
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
    let isAwait:Bool
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
            Text((isAwait ?  "思考中" : "正在输入") + "\(dots)")
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

