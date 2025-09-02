//
//  File name:     DataStorageView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com
//  Description:
//  History:
//  Created by uuneo on 2024/12/11.

import SwiftUI
import Defaults
import UniformTypeIdentifiers
import Photos
struct MoreOperationsView: View {
    @EnvironmentObject private var manager:AppManager
    @StateObject private var messageManager = MessagesManager.shared
    
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays
	@Default(.autoSaveToAlbum) var autoSaveToAlbum
   
    @Default(.badgeMode) var badgeMode
    @Default(.showMessageAvatar) var showMessageAvatar
    @Default(.defaultBrowser) var defaultBrowser
    @Default(.muteSetting) var muteSetting
    
    @Default(.deviceToken) var deviceToken
    @Default(.id) var id
    
    @State private var messages:[Message] = []
    @State private var allCount:Int = 0

    
    @State private var showDeleteAlert:Bool = false
    @State private var resetAppShow:Bool = false
    
    @State private var totalSize:UInt64 = 0
    @State private var cacheSize:UInt64 = 0
   
    @State private var showImport:Bool = false
    @State private var showexport:Bool = false
    
    
    @State private var showexportLoading:Bool = false
    @State private var showDriveCheckLoading:Bool = false
    
    
    @State private var cancelTask: Task<Void, Never>?
	
	var body: some View {
			List{
                
                Section{
                    if id.isEmpty{
                        SignInWithApple()
                    }
                    
                    
                    ListButton(leading: {
                        Label {
                            Text( "TOKEN")
                                .lineLimit(1)
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "captions.bubble")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.primary, .accent)
                                
                        }
                    }, trailing: {
                        HackerTextView(text: maskString(deviceToken), trigger: false)
                            .foregroundStyle(.gray)
                        
                        Image(systemName: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle( .accent, Color.primary)
                       
                        
                    }, showRight: false) {
                        if deviceToken != ""{
                            Clipboard.set(deviceToken)
                            Toast.copy(title: "复制成功")
                            
                        }else{
                            Toast.shared.present(title: "请先注册", symbol: "questionmark.circle.dashed")
                        }
                        return true
                    }
                    if !id.isEmpty{
                        ListButton(leading: {
                            Label {
                                Text( "ID")
                                    .lineLimit(1)
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "person.badge.key")
                                
                                    .symbolRenderingMode(.palette)
                                    .customForegroundStyle(Color.primary, .accent)
                            }
                        }, trailing: {
                            HackerTextView(text: maskUserId(id), trigger: false)
                                .foregroundStyle(.gray)
                            
                            Image(systemName: "doc.on.doc")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle( .accent, Color.primary)
                            
                        }, showRight: false) {
                            Clipboard.set(id)
                            Toast.copy(title:  "复制成功")
                            return true
                        }
                        
                    }
   
              
                } header:{
                    Text( "设备信息")
                        .textCase(.none)
                }
                
                Section {
                    Button{
                        guard !showexportLoading else { return }
                        self.showexportLoading = true
                        cancelTask = Task.detached(priority: .background) {
                            do{
                                let results = try await  DatabaseManager.shared.dbPool.read { db in
                                    try Message.fetchAll(db)
                                }
                                 DispatchQueue.main.async {
                                    self.messages = results
                                    self.showexportLoading = false
                                    self.showexport = true
                                }
                            }catch{
                                Log.error(error.localizedDescription)
                                 DispatchQueue.main.async{
                                    self.showexportLoading = false
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
                                    Label("正在处理数据", systemImage: "slowmo")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.tint, Color.primary)
                                        .symbolEffect(.rotate)
                                }
                            
                            Spacer()
                            Text(String(format: String(localized: "%d条消息"), messageManager.allCount) )
                                .foregroundStyle(Color.green)
                        }
                    }
                    .fileExporter(isPresented: $showexport, document: TextFileMessage(content: messages), contentType: .trnExportType, defaultFilename: "pushback_\(Date().formatString(format:"yyyy_MM_dd_HH_mm"))") { result in
                        switch result {
                            case .success(let success):
                            Log.debug(success)
                            case .failure(let failure):
                            Log.error(failure)
                        }
                        self.showexport = false
                    }
                    .onDisappear{
                        cancelTask?.cancel()
                        self.messages = []
                        self.showexport = false
                        
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
                
                
                Section(header: Text("默认浏览器设置")){
                    HStack{
                        Picker(selection: $defaultBrowser) {
                            ForEach(DefaultBrowserModel.allCases, id: \.self) { item in
                                Text(item.title)
                                    .tag(item)
                            }
                        }label:{
                            Text("默认浏览器")
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                    
                }
                
                Section{
                    
                    ListButton {
                        Label {
                            Text("小组件")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "window.shade.closed")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                
                        }
                    } action:{
                        manager.router.append(.widget(title: nil, data: "app"))
                        return true
                    }
                    
                }
                
                
             
                
				Section {
                    
                    Picker(selection: $badgeMode) {
                        Text( "自动").tag(BadgeAutoMode.auto)
                        Text( "自定义").tag(BadgeAutoMode.custom)
                    } label: {
                        Label {
                            Text( "角标模式")
                        } icon: {
                            Image(systemName: "app.badge")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .symbolEffect(.pulse, delay: 3)
                        }
                    }.onChange(of: badgeMode) { newValue in
                        if Defaults[.badgeMode] == .auto{
                            let unRead =  DatabaseManager.shared.unreadCount()
                            UNUserNotificationCenter.current().setBadgeCount( unRead )
                        }
                    }
                    
                    
                    Toggle(isOn: $showMessageAvatar) {
                        Label("显示图标", systemImage: showMessageAvatar ? "camera.macro.circle" : "camera.macro.slash.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .symbolEffect(.replace)
                        
                    }
					Picker(selection: $messageExpiration) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "消息存档")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
                                .foregroundStyle((messageExpiration == .no ? .red : (messageExpiration == .forever  ? .green : .yellow)), Color.primary)
                                .symbolEffect(.pulse, delay: 1)
						}
					}

                    
                    ListButton(leading: {
                        Label {
                            Text("取消静音分组")
                                .foregroundStyle(.textBlack)
                        } icon: {
                           
                            Image(systemName: "\(muteSetting.count).circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                
                        }
                    }, trailing: {
                        Image(systemName: "trash")
                             .symbolRenderingMode(.palette)
                             .foregroundStyle(.tint, Color.primary)
                    }, showRight: true) {
                        Defaults[.muteSetting] = [:]
                        return true
                    }
                
				}header:{
                    Text("信息页面")
                        .textCase(.none)
				}footer:{
					Text( "当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
						.foregroundStyle(.gray)
				}
				Section {
                    
                    Toggle(isOn: $autoSaveToAlbum) {
                        Label("自动保存到相册", systemImage: "a.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .symbolEffect(.rotate, delay: 3)
                            .onChange(of: autoSaveToAlbum) { newValue in
                                if newValue{
                                    PHPhotoLibrary.requestAuthorization{status in
                                        switch status {
                                        case .notDetermined:
                                            Toast.info(title:"用户尚未做出选择")
                                           
                                        case .restricted:
                                            Toast.info(title: "访问受限（可能是家长控制）")
                                   
                                        case .denied:
                                            Toast.info(title: "用户拒绝了访问权限")
                                     
                                        case .authorized:
                                            Toast.success(title: "用户已授权访问照片库")
            
                                        case .limited:
                                            Toast.info(title: "用户授予了有限的访问权限")
                                            
                                        @unknown default:
                                           break
                                      
                                        }
                                    }
                                }
                            }
                        
                    }
					Picker(selection: $imageSaveDays) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "图片存档")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
                                .symbolEffect(.pulse, delay: 1)
                                .foregroundStyle((imageSaveDays == .no ? .red : (imageSaveDays == .forever  ? .green : .yellow)), Color.primary)
						}
					}
				}header :{
					Text(  "图片存档")
						.foregroundStyle(.gray)
                        .textCase(.none)
				}footer:{
					Text("图片默认保存时间，本地化图片不受影响")
				}
                
                Section(header: Text("缓存大小限制, 建议多清几次")){
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
                            guard !showDeleteAlert else { return }
                            self.showDeleteAlert.toggle()
                        }label: {
                            HStack{
                                Spacer()
                                Label("清空缓存数据", systemImage: "trash.circle")
                                    .foregroundStyle(.white, Color.primary)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 5)
                                    .if(showDriveCheckLoading) {
                                        Label("正在处理数据", systemImage: "slowmo")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, Color.primary)
                                            .symbolEffect(.rotate)
                                    }
                               
                                Spacer()
                            }
                            
                        }.buttonStyle(BorderedProminentButtonStyle())
                            
                    }
                    
                    HStack{
                        Button{
                            self.resetAppShow.toggle()
                        }label: {
                            HStack{
                                Spacer()
                                Label("初始化App", systemImage: "arrow.3.trianglepath")
                                    .foregroundStyle(.white, Color.primary)
                                    .padding(.vertical, 5)
                                    .fontWeight(.bold)
                               
                                Spacer()
                            }
                            
                        }
                        .tint(.red)
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                
			}
			.navigationTitle("更多操作")
            .navigationBarTitleDisplayMode(.inline)
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
                            self.showDriveCheckLoading = true
                            if let cache = ImageManager.defaultCache(),
                               let imageCache = ImageManager.defaultCache(mode: .image),
                               let fileUrl = BaseConfig.getDir(.sounds),
                               let voiceUrl = BaseConfig.getDir(.voice)
                            {
                                cache.clearDiskCache()
                                imageCache.clearDiskCache()
                                manager.clearContentsOfDirectory(at: fileUrl)
                                manager.clearContentsOfDirectory(at: voiceUrl)
                                Defaults[.imageSaves] = []
                                
                                Toast.success(title: "清理成功")
                            }
                            
                            
                            DatabaseManager.shared.checkDriveData { success in
                                if success{
                                    Toast.success(title: "数据库整理成功")
                                }else{
                                    Toast.error(title: "数据库整理失败")
                                }
                              
                                 DispatchQueue.main.async{
                                    self.showDriveCheckLoading = false
                                    calculateSize()
                                }
                            }
                            
                            
                        }),
                              secondaryButton: .cancel())
                        
                    }
                
            }
		
	}
    
    
    func calculateSize(){
        if let group = CONTAINER,
           let soundsUrl = BaseConfig.getDir(.sounds),
           let imageUrl = BaseConfig.getDir(.image),
           let voiceUrl = BaseConfig.getDir(.voice) {
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
   
    
   
    
    fileprivate func importMessage(_ fileUrls: [URL]) -> String {
        guard let url = fileUrls.first else { return ""}
        do{
            if url.startAccessingSecurityScopedResource(){
                
                let data = try Data(contentsOf: url)
                // TODO:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let messages = try decoder.decode([Message].self, from: data)
                try?  DatabaseManager.shared.dbPool.write { db in
                    for message in messages {
                        try message.insert(db)
                    }
                }
                
            }
            
            return String(localized: "导入成功")
            
        }catch{
            Log.debug(error)
            return error.localizedDescription
        }
    }
    
  
    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) +  str }
        return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(4)
    }
    
    fileprivate func maskUserId(_ userId: String) -> String {
        let components = userId.split(separator: ".")
        guard components.count >= 2 else { return userId }

        let first = components.first ?? ""
        let last = components.last ?? ""

        return "\(first)*****\(last)"
    }
   
	
}
extension UInt64{
    func fileSize()->String{
        if self >= 1_073_741_824 { // 1GB
            return String(format: "%.2fGB", Double(self) / 1_073_741_824)
        } else if self >= 1_048_576 { // 1MB
            return String(format: "%.2fMB", Double(self) / 1_048_576)
        } else if self >= 1_024 { // 1KB
            return String(format: "%dKB", self / 1_024)
        } else {
            return "\(self)B" // 小于 1KB 直接显示字节
        }
    }
}
#Preview {
    MoreOperationsView()
}
