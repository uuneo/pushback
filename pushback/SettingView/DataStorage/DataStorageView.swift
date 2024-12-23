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

struct DataStorageView: View {
	@ObservedResults(Message.self) var messages
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays
	@Default(.cacheSize) var cacheSize
	@State private var showImport:Bool = false
	@State private var select:Int = 0

	@State private var showDeleteAlert:Bool = false
	@State private var showexport:Bool = false

	var body: some View {
		NavigationStack{
			List{
				Section {

					Button{
						self.showexport.toggle()
					}label: {
						HStack{

							Label("导出", systemImage: "arrow.up.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)



							Spacer()
							Text(String(format: String(localized: "%d条消息"), messages.count) )
								.foregroundStyle(Color.green)
						}
					}
					.fileExporter(isPresented: $showexport, document: TextFileMessage(content: messages), contentType: .trnExportType, defaultFilename: "pushback_\(Date().formatString(format:"yyyy_MM_dd_HH_mm"))") { result in
						switch result {
							case .success(let success):
								print(success)
							case .failure(let failure):
								print(failure)
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

							Spacer()

						}
					}


					.fileImporter(isPresented: $showImport, allowedContentTypes: [.trnExportType], allowsMultipleSelection: false, onCompletion: { result in
						switch result {
							case .success(let files):
								Toast.shared.present(title: RealmManager.shared.importMessage(files), symbol: .info)
							case .failure(let err):
								Toast.shared.present(title: err.localizedDescription, symbol: .error)
						}
					})



				} header: {
					Text( "导出消息列表")
				} footer:{
					Text("只能导入.exv结尾的JSON数据")
				}




				Section {


					Picker(selection: $messageExpiration) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "默认保存时间")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle((messageExpiration.days == 0 ? .red : (messageExpiration.days == -1 ? .green : .yellow)), Color.primary)



						}
					}


				}header:{
					Text( "消息存档")
				}footer:{

					Text( "当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
						.foregroundStyle(.gray)

				}




				Section {

					NavigationLink {

						ImageCacheView()
							.toolbar(.hidden, for: .tabBar)
							.navigationTitle("图片缓存")

						//						if #available(iOS 17.0, *){
						//							ImageHomeView()
						//
						//						}else{
						//							ImageCacheView()
						//								.toolbar(.hidden, for: .tabBar)
						//								.navigationTitle("图片缓存")
						//						}

					} label: {
						Label("图片缓存", systemImage: "photo.on.rectangle")
							.symbolRenderingMode(.palette)
							.foregroundStyle( .tint, Color.primary)
					}


					Picker(selection: $imageSaveDays) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "默认保存时间")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle((imageSaveDays.days == 0 ? .red : (imageSaveDays.days == -1 ? .green : .yellow)), Color.primary)

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
							Image(systemName: "chart.pie.fill")
								.foregroundStyle(Color.darkLight)
								.background(
									RoundedRectangle(cornerRadius: 10)
										.backgroundStyle(.orange)
								)
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
			.navigationTitle("数据与存储")
			.alert(isPresented: $showDeleteAlert) {
				Alert(title: Text("是否确定清空?"),  message: Text("删除后不能还原!!!"),
					  primaryButton: .destructive(Text("清空"),
												  action: {
					if let cache = ImageManager.defaultCache(){
						cache.clearDiskCache()
						Defaults[.images] = []
						Toast.shared.present(title: "清理成功", symbol: .success)
					}

				}),
					  secondaryButton: .cancel())

			}
		}
	}

	func getUseSize()->String{

		if let totalSize = try? ImageManager.defaultCache()?.diskStorage.totalSize(){

			if totalSize > 1 << 30{
				return "\(totalSize >> 30)GB"
			}else{
				return "\(totalSize >> 20)MB"
			}
		}


		return "0"
	}
}

#Preview {
	DataStorageView()
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
		self.content = try decoder.decode([Message].self, from: data)
	}

	// 写入内容到文件
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted // 格式化输出
		let data = try encoder.encode(content)
		return FileWrapper(regularFileWithContents: data)
	}
}
