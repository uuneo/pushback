//
//  File name:     DataStorageView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/11.


import SwiftUI
import RealmSwift
import Defaults
import UniformTypeIdentifiers
import SwiftyJSON
import Photos

struct MoreOperationsView: View {
    @EnvironmentObject private var manager:PushbackManager
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays
	@Default(.autoSaveToAlbum) var autoSaveToAlbum
    @ObservedResults(Message.self) var messages
    @Default(.badgeMode) var badgeMode
    @Default(.showMessageAvatar) var showMessageAvatar
   

    @State private var showImport:Bool = false
    @State private var showexport:Bool = false
	

	var body: some View {

			List{
            
                
                Section {

                    Button{
                        self.showexport.toggle()
                    }label: {
                        HStack{

                            Label("导出", systemImage: "arrow.up.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .symbolEffect(.wiggle, delay: 3)
                            
                            Spacer()
                            Text(String(format: String(localized: "%d条消息"), messages.count) )
                                .foregroundStyle(Color.green)
                        }
                    }
                    .disabled(messages.count == 0)
                    .fileExporter(isPresented: $showexport, document: TextFileMessage(content: messages), contentType: .trnExportType, defaultFilename: "pushback_\(Date().formatString(format:"yyyy_MM_dd_HH_mm"))") { result in
                        switch result {
                            case .success(let success):
                            Log.debug(success)
                            case .failure(let failure):
                            Log.error(failure)
                        }
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
                                Toast.info(title: msg)
                            case .failure(let err):
                                Toast.error(title: err.localizedDescription)
                        }
                    })



                } header: {
                    Text( "导出消息列表")
                        .textCase(.none)
                } footer:{
                    Text("只能导入.exv结尾的JSON数据")
                }
                
                
                Button{
                    PushbackManager.openSetting()
                }label: {
                    HStack(alignment:.center){

                        Label {
                            Text( "系统设置")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "gear.circle")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .symbolEffect(.rotate)

                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
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
                            RealmManager.handler{ proxy in
                                let unRead = proxy.objects(Message.self).filter({ !$0.read }).count
                                UNUserNotificationCenter.current().setBadgeCount( unRead )
                            }
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
                                            Toast.info(title: String(localized: "用户尚未做出选择"))
                                           
                                        case .restricted:
                                            Toast.info(title: String(localized: "访问受限（可能是家长控制）"))
                                   
                                        case .denied:
                                            Toast.info(title: String(localized: "用户拒绝了访问权限"))
                                     
                                        case .authorized:
                                            Toast.success(title: String(localized: "用户已授权访问照片库"))
            
                                        case .limited:
                                            Toast.info(title: String(localized: "用户授予了有限的访问权限"))
                                            
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
                
			}
			.navigationTitle("更多操作")
			
		
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
                            messageObject.search = message["search"].string ?? ""
                            
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

#Preview {
    MoreOperationsView()
}


struct TextFileMessage: FileDocument {

	static var readableContentTypes: [UTType] { [.trnExportType] } // 使用 JSON 文件类型

	var content: [Message]

	// 初始化器（设置默认内容）
	init(content: Results<Message>) {
		self.content = Array(content)
	}

	// 从文件中读取内容
	init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents else {
			throw CocoaError(.fileReadCorruptFile)
		}
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .secondsSince1970
		let content = try decoder.decode([Message].self, from: data)
		self.content = content
	}

	// 写入内容到文件
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted // 格式化输出
		encoder.dateEncodingStrategy = .secondsSince1970

		let data = try encoder.encode(content)
		return FileWrapper(regularFileWithContents: data)
	}
    
    
   
}
