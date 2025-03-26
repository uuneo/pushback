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
	@ObservedResults(Message.self) var messages
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays
	@Default(.cacheSize) var cacheSize
	@Default(.autoSaveToAlbum) var autoSaveToAlbum
    @Default(.defaultBrowser) var defaultBrowser
    @Default(.badgeMode) var badgeMode
    @Default(.showMessageAvatar) var showMessageAvatar
	@State private var showImport:Bool = false
	@State private var select:Int = 0

	@State private var showDeleteAlert:Bool = false
	@State private var showexport:Bool = false

	var body: some View {
		NavigationStack{
			List{
                
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

                Section(header: Text("端到端加密")){

                    NavigationLink{
                        CryptoConfigView()
                    }label: {
                        Label {
                            Text( "算法配置")
                        } icon: {
                            Image(systemName: "bolt.shield")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                .symbolEffect(.pulse, delay: 5)
                        }
                    }
                    
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
                        RealmManager.ChangeBadge()
                    }

                }


                
                
                
                
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
				} footer:{
					Text("只能导入.exv结尾的JSON数据")
				}
                

               

				Section {
                    
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
				}footer:{

					Text( "当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
						.foregroundStyle(.gray)

				}


                


				Section {


					Section {
						Toggle(isOn: $autoSaveToAlbum) {
							Label("自动保存到相册", systemImage: "a.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle( .tint, Color.primary)
                                .symbolEffect(.rotate, delay: 3)
                                .onChange(of: autoSaveToAlbum) { newValue in
                                    if newValue{
                                        debugPrint(newValue)
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

				}footer:{
					Text("图片默认保存时间，本地化图片不受影响")
				}
                
                
                

				Section(header: Text("缓存大小限制")){



					SlideLineView(data: $cacheSize ){
						ZStack{

							if let data = CacheSizeLimit.allCases.first{
								HStack{
									Text(data.title)
									Spacer(minLength: 0)
								}.font(.caption)
							}



							HStack(spacing: 0){
								Spacer()
								ForEach(CacheSizeLimit.allCases, id: \.self){ item in
									if item != CacheSizeLimit.allCases.first &&  item != CacheSizeLimit.allCases.last{
										Text(item.title)
										Spacer()
									}
								}
							}
							.font(.caption)



							if let data = CacheSizeLimit.allCases.last{
								HStack{
									Spacer(minLength: 0)
									Text(data.title)

								}.font(.caption)
							}
						}

					}
					.frame(width: UIScreen.main.bounds.width - 80, height: 60)
					.padding(.horizontal)

				}

				Section(header: Text("存储用量")){

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
						Text("\(getUseSize())/\(cacheSize.title)")



					}


					HStack{
						Button{
							self.showDeleteAlert.toggle()
						}label: {
							HStack{
								Spacer()
								Text("清空缓存")
									.fontWeight(.bold)
									.padding(.vertical, 5)
								Spacer()
							}

						}.buttonStyle(BorderedProminentButtonStyle())


					}
				}







			}
			.navigationTitle("更多操作")
			.alert(isPresented: $showDeleteAlert) {
				Alert(title: Text("是否确定清空?"),  message: Text("删除后不能还原!!!"),
					  primaryButton: .destructive(Text("清空"),
												  action: {
					if let cache = ImageManager.defaultCache(){
						cache.clearDiskCache()
                        Toast.success(title: String(localized: "清理成功"))
					}

				}),
					  secondaryButton: .cancel())

			}
		}
	}

	func getUseSize()->String{

        if let totalSize = try? ImageManager.defaultCache()?.diskStorage.totalSize(){
            
            if totalSize >= 1_073_741_824 { // 1GB
                return String(format: "%.2fGB", Double(totalSize) / 1_073_741_824)
            } else if totalSize >= 1_048_576 { // 1MB
                return String(format: "%.2fMB", Double(totalSize) / 1_048_576)
            } else if totalSize >= 1_024 { // 1KB
                return String(format: "%dKB", totalSize / 1_024)
            } else {
                return "\(totalSize)B" // 小于 1KB 直接显示字节
            }
        }


		return "0"
	}
    
    private func importMessage(_ fileUrls: [URL]) -> String {
        do{
            for url in fileUrls{
                
                if url.startAccessingSecurityScopedResource(){
                    
                    let data = try Data(contentsOf: url)
                    
                    guard let arr = try JSON(data: data).array else { return String(localized: "文件格式错误") }
                    
                    RealmManager.shared.realm { proxy in
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
                            messageObject.video = message["video"].string
                            messageObject.ttl = ExpirationTime.forever.days
                            messageObject.createDate = Date(timeIntervalSince1970: TimeInterval(createDate))
                            messageObject.userInfo = message["userInfo"].string ?? ""
                            
                            proxy.add(messageObject, update: .modified)
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
