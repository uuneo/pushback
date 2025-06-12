//
//  DeviceInfoSettingsView.swift
//  pushme
//
//  Created by lynn on 2025/6/17.
//
import SwiftUI
import Defaults
import PhotosUI



struct DeviceInfoSettingsView: View {
    @Default(.user) var user
    @Default(.deviceToken) var deviceToken
    @Default(.voipDeviceToken) var voipDeviceToken
    @Default(.id) var userID
    @State private var showTextAnimation:Bool = false
    @State private var showIdAnimation:Bool = false
    @State private var showVoipAnimation:Bool = false
    
    @State private var selectItem: PhotosPickerItem? = nil
    
    @State private var edited:Bool = false
    
    @State private var caller:String = ""
    @State private var nikeName:String = ""
    @State private var callerVer:Bool = false
    @State private var avatar:URL? = nil
    @State private var loading:Bool = false
    
    @State private var saveLoading:Bool = false
    @State private var imageLoading:Bool = false
    
    private let debouncer = Debouncer()
    
    init(){
        let user = Defaults[.user]
        self._caller = State(wrappedValue: user.caller)
        self._avatar = State(wrappedValue: user.avatar)
        self._nikeName = State(wrappedValue: user.name)
    }
    
    var numberColor:Color{
        
        if  caller == user.caller {
            return Color.clear
        }
        return callerVer ? .blue : .red
    }
    
    
    var body: some View {
        Form{
            
            HStack{
                Spacer()
                
                
                    PhotosPicker(selection: $selectItem) {
                        Group{
                            if let avatar = avatar, let uiimage = UIImage(contentsOfFile: avatar.path()){
                                Image(uiImage: uiimage)
                                    .resizable()
                            }else{
                                Image("logo")
                                    .resizable()
                            }
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .blur(radius: imageLoading ? 5 : 0)
                        .overlay{
                            if imageLoading{
                                ZStack{
                                    ProgressView()
                                        .scaleEffect(2)
                                        .tint(.blue)
                                        .blendMode(.difference)
                                }
                            }
                        }
                        .clipShape(Circle())
                        .padding(.top, 35)
                        .overlay(alignment: .bottomTrailing, content: {
                            Image(systemName: "plus.viewfinder")
                        })
                    }
                    .disabled(imageLoading)
               
                Spacer()
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .onChange(of: selectItem) { newItem in
                
                guard let newItem else{ return }
                self.imageLoading = true
                
                Task.detached(priority: .userInitiated) {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiimage =  data.toThumbnail(max: 300),
                       let data = uiimage.pngData()
                    {
                        
                        guard let path = BaseConfig.documentUrl("avatar.png", fileType: .png)else { return }
                        
                        try data.write(to: path)
                        
                        await MainActor.run {
                            user.avatar = path
                        }
                        if await CallCloudManager.shared.save(user,avatar: true){
                            await MainActor.run {
                                avatar = user.avatar
                            }
                            Toast.success(title: "保存成功")
                        }else{
                            await MainActor.run {
                                user.avatar = avatar
                            }
                            Toast.error(title: "保存失败")
                        }
                    }
                    await MainActor.run {
                        self.selectItem = nil
                        self.imageLoading = false
                    }
                }
            }
            
            
            Section{
                TextField("昵称", text: $nikeName)
                    .autocapitalization(.none)
                    .customField(
                        icon: "phone.and.waveform", false
                    )
                    .disabled(!edited)
            }header: {
                Text(verbatim: "昵称")
                    .padding(.leading)
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            
            Section{
                TextField("CallID", text: $caller)
                    .autocapitalization(.none)
                    .keyboardType(.numberPad)
                    .customField( icon: "123.rectangle", false)
                    .background(numberColor)
                    .disabled(!edited)
                    .onChange(of: caller) { newValue in
                        if newValue.count > 15{
                            caller = String(newValue.prefix(15))
                        }else{
                            guard newValue.count > 0 else{ return }
                            self.callerVer = false
                            debouncer.debounce(delay: 0.2) {
                                self.loading = true
                                
                                Task.detached(priority: .userInitiated) {
                                    let success = await CallCloudManager.shared.vercaller(id: newValue)
                                    await MainActor.run {
                                        self.callerVer = success
                                        self.loading = false
                                    }
                                }
                                
                            }
                        }
                        
                    }
                
            }header: {
                if loading{
                    HStack(spacing: 0){
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(verbatim: "检查可用性")
                            .padding(.leading)
                    }
                }else{
                    HStack(spacing: 0){
                        if caller != user.caller{
                            Circle()
                                .fill( callerVer ? Color.blue : Color.red )
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(verbatim: "通话ID")
                            .padding(.leading)
                    }
                }
            }
            .textCase(.none)
            .listRowInsets(EdgeInsets())
            .listRowSpacing(0)
            
            Section(header:Text( "设备推送令牌")) {
                ListButton(leading: {
                    Label {
                        Text( "消息")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "captions.bubble")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .tint)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(deviceToken), trigger:showTextAnimation)
                        .foregroundStyle(.gray)
                    
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                    
                }, showRight: false) {
                    if deviceToken != ""{
                        Clipboard.set(deviceToken)
                        Toast.copy(title: "复制成功")
                        
                    }else{
                        Toast.shared.present(title: "请先注册", symbol: "questionmark.circle.dashed")
                    }
                    self.showTextAnimation.toggle()
                    return true
                }
                
                ListButton(leading: {
                    Label {
                        Text(verbatim: "VOIP")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "phone.bubble.left")
                        
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .tint)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(voipDeviceToken), trigger: showVoipAnimation)
                        .foregroundStyle(.gray)
                    
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                    
                }, showRight: false) {
                    Clipboard.set(voipDeviceToken)
                    Toast.copy(title: "复制成功")
                    self.showVoipAnimation.toggle()
                    return true
                }
                
                
                
                ListButton(leading: {
                    Label {
                        Text( "ID")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "person.badge.key")
                        
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .tint)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(userID), trigger: showIdAnimation)
                        .foregroundStyle(.gray)
                    
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                    
                }, showRight: false) {
                    Clipboard.set(userID)
                    Toast.copy(title:  "复制成功")
                    self.showIdAnimation.toggle()
                    return true
                }
                
                
                
            }
            
            
        }
        .disabled(saveLoading)
        .blur(radius: saveLoading ? 5 : 0)
        .overlay{
            if saveLoading{
                ProgressView("处理中")
            }
        }
        .navigationTitle("设备资料")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button{
                    
                    if edited {
                        self.hideKeyboard()
                        guard caller != user.caller || nikeName != user.name else {
                            self.edited = false
                            return
                        }
                        self.saveLoading = true
                        var result = user
                        if caller != user.caller, callerVer{
                            result.caller = caller
                        }
                        if nikeName != user.name, !nikeName.isEmpty{
                            result.name = nikeName
                        }
                        
                        Task.detached(priority: .userInitiated) {
                            let success = await CallCloudManager.shared.save(result)
                            await MainActor.run {
                                if success {
                                    if caller != user.caller, callerVer{
                                        self.user.caller = caller
                                    }
                                    if nikeName != user.name, !nikeName.isEmpty{
                                        self.user.name = nikeName
                                    }
                                    Toast.success(title: "保存成功")
                                }else{
                                    Toast.error(title: "保存失败")
                                }
                                self.edited = false
                                self.saveLoading = false
                                
                            }
                            
                        }
                        
                    }else{
                        self.edited = true
                    }
                }label: {
                    Text(edited ? "保存" : "编辑")
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack{
                    Spacer()
                    Button {
                        self.hideKeyboard()
                    }label:{
                        Text("完成")
                    }
                }
            }
        }
        .task {
            Task.detached(priority: .background) {
                if let call = await CallCloudManager.shared.downloadUser(id: Defaults[.id]){
                    
                    do{
                        var user = Defaults[.user]
                        if let avatar = call.avatar,
                           let path = BaseConfig.documentUrl("avatar.png", fileType: .png){
                            try? FileManager.default.removeItem(at: path)
                            try FileManager.default.copyItem(atPath: avatar.path(), toPath: path.path())
                            user.avatar = path
                            await MainActor.run {
                                self.avatar = path
                            }
                        }
                        
                        if user.caller != call.caller{
                            user.caller = call.caller
                            await MainActor.run {
                                self.caller = call.caller
                            }
                            
                        }
                        if user.name != call.name{
                            user.name = call.name
                            await MainActor.run {
                                self.nikeName = call.name
                            }
                        }
                        
                        Defaults[.user] = user
                    }catch{
                        debugPrint(error.localizedDescription)
                    }
                    
                }
            }
        }
    }
    
    
    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) +  str }
        return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(6)
    }
    
}


final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    
    init(queue: DispatchQueue = .main) {
        self.queue = queue
    }
    
    func debounce(delay: TimeInterval, action: @escaping () -> Void) {
        // 取消之前的任务
        workItem?.cancel()
        
        // 创建新任务
        workItem = DispatchWorkItem(block: action)
        
        // 延迟执行
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}
