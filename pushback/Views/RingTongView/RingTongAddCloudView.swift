//
//  RingTongAddCloudView.swift
//  pushback
//
//  Created by He Cho on 2024/11/11.
//

import Foundation
import SwiftUI


struct RingTongAddCloudView:View {
	
	@State private var fileName:String = ""
	@State private var fileTag:String = ""
	var fileUrl:URL
	@FocusState private var fileNameShow
	@FocusState private var fileTagShow
	
	var dismiss:()-> Void
	
	
	@StateObject private var cloud = RingsTongCloudKit.shared
	var body: some View {
		NavigationStack{
			List{
				Section {
					TextField(text: $fileName) {
						Label("文件名", systemImage: "pencil")
					}
					.focused($fileNameShow)
					.customField(icon: "pencil")
				}  header: {
					Text("文件名不能重复,不要携带.caf")
				}
				
				
				Section {
					TextField(text: $fileTag) {
						Label("铃声描述词", systemImage: "pencil")
					}
					.focused($fileTagShow)
					.customField(icon: "pencil")
				} header: {
					Text("描述词逗号间隔")
				}

			}
			.navigationTitle("云端共享")
			.toolbar {
				
				
				ToolbarItemGroup(placement: .keyboard) {
					Button( "清除") {
						if fileNameShow{
							fileName = ""
						}else{
							fileTag = ""
						}
					}
					Spacer()
					Button( "完成") {
						PushbackManager.shared.hideKeyboard()
					}
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button{
						if fileName.count < 5 {
							Toast.shared.present(title: String(localized: "文件名不能小于5个字符"), symbol: .info)
							return
						}
						
						if fileTag.count < 1{
							Toast.shared.present(title: String(localized: "描述不能为空"), symbol: .info)
							return
						}
						
						
						
						if let data = RingtoneCloudData(name: fileName, prompt: fileTag.components(separatedBy: ","), count: 0, data: fileUrl){
							cloud.saveRingtone(data) { err in
								if let err{
									debugPrint(err.localizedDescription)
									Toast.shared.present(title: String(localized: "文件(名)重复"), symbol: .error)
								}else{
									Toast.shared.present(title: String(localized: "分享成功"), symbol: .success)
								}
							}
						}
						
						
						
					}label: {
						Text("上传")
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
		
	}
}




#Preview {
	
	RingtongView()
		.environmentObject(PushbackManager.shared)
	
}
