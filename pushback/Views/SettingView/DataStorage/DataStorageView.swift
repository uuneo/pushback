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

struct DataStorageView: View {
	@ObservedResults(Message.self) var messages
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays

	@State private var showImport:Bool = false
	

    var body: some View {
		NavigationStack{
			List{
				Section {

					HStack{
						ShareLink(item: MessageExportJson(data: Array(messages)), preview:
									SharePreview(Text(String(format: String(localized: "导出%d条通知消息"), messages.count)), image: Image("json_png"), icon: "trash")) {
							Label("导出", systemImage: "arrow.up.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
						}


						Spacer()
						Text(String(format: String(localized: "%d条消息"), messages.count) )
							.foregroundStyle(Color.green)
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




			}
			.navigationTitle("数据与存储")
		}
    }
}

#Preview {
    DataStorageView()
}
