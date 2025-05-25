//
//  PrivacySecurity.swift
//  pushback
//
//  Created by lynn on 2025/4/13.
//

import SwiftUI
import Defaults
import RealmSwift
import SwiftyJSON

struct PrivacySecurity:View {
    
    @Default(.deviceToken) var deviceToken
    @Default(.id) var userID
    @EnvironmentObject private var groupModel: MessagesData
    @EnvironmentObject private var manager:AppManager
    
    @State private var showTextAnimation:Bool = false
    @State private var showIdAnimation:Bool = false
    
    @State private var showDeleteAlert:Bool = false
    @State private var resetAppShow:Bool = false
    
    @State private var totalSize:UInt64 = 0
    @State private var cacheSize:UInt64 = 0
   
    @State private var showImport:Bool = false
    @State private var showexport:Bool = false
    
    @State private var showexportLoading:Bool = false
    
    @State private var messages:[MessageCopy] = []
    
    var body: some View {
        List{
            
            
            
            Section(header:Text( "设备推送令牌")) {
                ListButton(leading: {
                    Label {
                        Text( "令牌")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "key")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .tint)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(deviceToken), trigger:showTextAnimation)
                        .foregroundStyle(.gray)
                        
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .scaleEffect(0.9)
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
                        Text( "ID")
                            .lineLimit(1)
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "person.crop.square.filled.and.at.rectangle")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .tint)
                    }
                }, trailing: {
                    HackerTextView(text: maskString(userID,isID: true), trigger: showIdAnimation)
                        .foregroundStyle(.gray)
                        
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .scaleEffect(0.9)
                }, showRight: false) {
                    Clipboard.set(userID)
                    Toast.copy(title:  "复制成功")
                    self.showIdAnimation.toggle()
                    return true
                }
               
            }
            
            
            Section {

                Button{
                    
                    Task.detached(priority: .userInitiated) {
                        DispatchQueue.main.async{
                            self.showexportLoading = true
                        }
                        if let realm = try? Realm(){
                            let messages = realm.objects(Message.self)
                                .sorted(byKeyPath: "createDate", ascending: false)
                            var copyarr:[MessageCopy] = []
                            for item in messages{
                                copyarr.append(item.toCopy())
                            }
                            DispatchQueue.main.async{
                                self.messages = copyarr
                                self.showexportLoading = false
                                self.showexport.toggle()
                            }
                        }
                    }
                    
                    
                   
                }label: {
                    HStack{

                        Label("导出", systemImage: "arrow.up.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(.wiggle, delay: 3)
                            .if(showexportLoading) {
                                ProgressView()
                            }
                        
                        Spacer()
                        Text(String(format: String(localized: "%d条消息"), groupModel.allCount) )
                            .foregroundStyle(Color.green)
                    }
                }
                .disabled(groupModel.allCount == 0 || showexportLoading)
                .if(showexport){view in
                    
                    view
                       
                        .fileExporter(isPresented: $showexport,
                                      document: TextFileMessage(content: messages),
                                      contentType: .trnExportType,
                                      defaultFilename: "pushback_\(Date().formatString(format:"yyyy_MM_dd_HH_mm"))") { result in
                            switch result {
                            case .success(let success):
                                Log.debug(success)
                            case .failure(let failure):
                                Log.error(failure)
                            }
                            self.showexport = false
                        }
                                      
                }
                .onDisappear{
                    self.messages = []
                }

                Button{
                    self.showImport.toggle()
                }label: {
                    HStack{

                        Label( "导入", systemImage: "arrow.down.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(.wiggle, delay: 6)

                        Spacer()

                    }
                }


                .fileImporter(isPresented: $showImport, allowedContentTypes: [.trnExportType], allowsMultipleSelection: false, onCompletion: { result in
                    switch result {
                    case .success(let files):
                        let msg = importMessage(files)
                        Toast.shared.present(title: msg, symbol: .info)
                    case .failure(let err):
                        Toast.shared.present(title: err.localizedDescription, symbol: .error)
                    }
                })



            } header: {
                Text( "导出消息列表")
                    .textCase(.none)
            } footer:{
                Text("只能导入.exv结尾的JSON数据")
            }
            
            
            Section(header: Text("端到端加密")){
                
                ListButton {
                    Label {
                        Text( "算法配置")
                    } icon: {
                        Image(systemName: "bolt.shield")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(.pulse, delay: 5)
                    }
                } action: {
                    manager.router.append(.crypto(nil))
                    return true
                }
               
            }
            

            
           
            

            Section(header: Text("缓存大小限制")){

                HStack{
                    Label {
                        Text("存储使用")
                    } icon: {
                        Image(systemName: "externaldrive.badge.person.crop")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .symbolEffect(.pulse, delay: 3)
                    }
                    Spacer()
                    
                    Text(totalSize.fileSize())
                        .onAppear{
                            calculateSize()
                        }
                    
                    
                }


                HStack{
                    Button{
                        self.showDeleteAlert.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text(cacheSize.fileSize())
                                .padding(.horizontal, 3)
                            Text("清空缓存")
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                           
                            Spacer()
                        }

                    }.buttonStyle(BorderedProminentButtonStyle())
                        .disabled(cacheSize == 0)

                }
                
                HStack{
                    Button{
                        self.resetAppShow.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text("初始化App")
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                           
                            Spacer()
                        }
                        

                    }
                    .tint(.red)
                    .buttonStyle(BorderedProminentButtonStyle())

                }
                
                
           

            }

           
            
           
        }.navigationTitle("隐私与安全")
            .if(resetAppShow){ view in
                view
                    .alert(isPresented: $resetAppShow) {
                        Alert(title: Text("危险操作!!! 恢复初始化."),
                              message:  Text("将丢失所有数据"),
                              primaryButton: .destructive(Text("确定"), action: { resetApp() }),
                              secondaryButton: .cancel()
                        )}
            }
            .if(showDeleteAlert){ view in
                view
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("是否确定清空?"),  message: Text("删除后不能还原!!!"),
                              primaryButton: .destructive(Text("清空"),
                                                          action: {
                            if let cache = ImageManager.defaultCache(),
                               let imageCache = ImageManager.defaultCache(mode: .image),
                               let fileUrl = BaseConfig.getSoundsGroupDirectory(),
                               let voiceUrl = BaseConfig.getVoiceDirectory()
                            {
                                cache.clearDiskCache()
                                imageCache.clearDiskCache()
                                manager.clearContentsOfDirectory(at: fileUrl)
                                manager.clearContentsOfDirectory(at: voiceUrl)
                                Defaults[.imageSaves] = []
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    calculateSize()
                                }
                                Toast.success(title: "清理成功")
                            }
                            
                        }),
                              secondaryButton: .cancel())
                        
                    }
                
            }
        
    }
    
    func calculateSize(){
        if let group = CONTAINER,
           let soundsUrl = BaseConfig.getSoundsGroupDirectory(),
           let imageUrl = BaseConfig.getImagesDirectory(),
           let voiceUrl = BaseConfig.getVoiceDirectory()
        {
            self.totalSize = manager.calculateDirectorySize(at: group)
            
            self.cacheSize =  manager.calculateDirectorySize(at: soundsUrl) +  manager.calculateDirectorySize(at: imageUrl) +
            manager.calculateDirectorySize(at: voiceUrl)
            
        }
    }
    
    
    fileprivate func resetApp(){
        if let group = CONTAINER{
            manager.clearContentsOfDirectory(at: group)
            exit(0)
        }
        
    }
   

    
    fileprivate func maskString(_ str: String, isID:Bool = false) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) +  str }
        if isID{
            return String(repeating: "*", count: 3) + str.suffix(9)
        }else{
            return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(6)
        }
       
    }
    
    fileprivate func importMessage(_ fileUrls: [URL]) -> String {
        do{
            for url in fileUrls{
                
                if url.startAccessingSecurityScopedResource(){
                    
                    let data = try Data(contentsOf: url)
                    
                    guard let arr = try JSON(data: data).array else { return String(localized: "文件格式错误") }
                    
                   
                    autoreleasepool {
                        var messages:[Message] = []
                        for message in arr {
                            
                            guard let id = message["id"].string,let createDate = message["createDate"].int64 else { continue }
                            
                            let messageObject = Message()
                            if let idString = UUID(uuidString: id){ messageObject.id = idString }
                            
                            messageObject.title = message["title"].string
                            messageObject.body = message["body"].string
                            messageObject.url = message["url"].string
                            messageObject.group = message["group"].string ?? String(localized: "导入数据")
                            messageObject.read = true
                            messageObject.level = message["level"].int ?? 1
                            messageObject.image = message["image"].string
                            messageObject.ttl = ExpirationTime.forever.days
                            messageObject.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
                           
                            
                            messages.append(messageObject)
                            
                            if messages.count == 1000 {
                                let newMessage = messages
                                RealmManager.handler { proxy in
                                    proxy.writeAsync {
                                        proxy.add(newMessage, update: .modified)
                                    }
                                }
                                
                                messages = []
                            }
                        }
                        RealmManager.handler { proxy in
                            proxy.writeAsync {
                                proxy.add(messages, update: .modified)
                            }
                        }
                    }
                }
                
                
                
            }
            
            return String(localized: "导入成功")
            
        }catch{
            Log.debug(error)
            return error.localizedDescription
        }
    }
    
    
}
