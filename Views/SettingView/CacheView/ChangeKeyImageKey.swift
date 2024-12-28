//
//  File name:     ChangeKeyImageKey.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/24.
	
import SwiftUI


struct ChangeKeyImageKey: View{
	@Environment(\.dismiss) var dismiss

	var image:ImageModel

	@State private var localName:String = ""
	@FocusState private var photoNamesShow
	var body: some View{
		NavigationStack{
			VStack(alignment: .leading){

				Text("远程本地化")
					.font(.largeTitle)
					.fontWeight(.heavy)
					.padding(.top, 5)
					.onAppear{
						self.localName = image.another ?? image.url
					}

				Divider()

				Text("原始地址:")
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(.gray)
					.padding(.top, -5)

				Text(image.url)
					.lineLimit(1)
					.font(.title3)
					.customField(icon: "doc.on.doc"){
						PushbackManager.shared.copy(image.url)
						Toast.shared.present(title: String(localized: "复制成功"), symbol: "doc.on.doc")
					}

				Divider()
				Text("输入一个字符串 远程可以直接使用：")
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(.gray)
					.padding(.top, -5)

				TextField(text:  $localName) {
					Label("输入本地地址", systemImage: "pencil")
				}
				.focused($photoNamesShow)
				.padding(.vertical, 10)
				.customField(icon: "pencil"){
					self.photoNamesShow.toggle()
				}


				Spacer()

			}
			.padding()
			.toolbar {


				ToolbarItemGroup(placement: .keyboard) {
					Button("清除") {
						localName = ""
					}
					Spacer()
					Button("完成") {
						PushbackManager.shared.hideKeyboard()
					}
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button{
						if ImageManager.changeLocalKey(image.url, key: localName) {
							Toast.shared.present(title: String(localized: "修改成功"), symbol: .success)
							self.dismiss()
						}else{
							Toast.shared.present(title: String(localized: "修改失败"), symbol: .error)
						}
					}label: {
						Text("完成")
					}
				}



				ToolbarItem(placement: .topBarLeading) {
					Button(action: {
						self.dismiss()
					}, label: {
						Image(systemName: "arrow.left")
							.font(.title2)
							.foregroundStyle(.gray)
					})
				}

			}

		}
		.presentationDetents([.height(360)])
		.interactiveDismissDisabled()
		.toolbar(.hidden, for: .navigationBar)
	}
}
