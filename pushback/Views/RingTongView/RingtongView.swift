//
//  RingtongView.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import SwiftUI
import AVFoundation
import UIKit

struct RingtongView: View {
	@Environment(\.dismiss) var dismiss
	@EnvironmentObject private var manager:PushbackManager
	@State private var showUpload:Bool = false
	
	var body: some View {
		List {
			Section{
				ForEach(manager.customSounds, id: \.self) { url in
					RingtoneItemView(audio: url)
					
				}.onDelete { indexSet in
					for index in indexSet{
						manager.deleteSound(url: manager.customSounds[index])
					}
				}
			}header: {
				Text(String(localized:  "自定义铃声"))
			}
			
			
			
			Section {
				HStack{
					Spacer()
					Button {
						self.showUpload.toggle()
#if DEBUG
						print("上传铃声")
#endif
						
						
					} label: {
						Label(String(localized:  "上传铃声"), systemImage: "waveform" )
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint)
						
					}
					.fileImporter(isPresented: $showUpload, allowedContentTypes:  UTType.types(tag: "caf", tagClass: UTTagClass.filenameExtension,conformingTo: nil)) { result in
						switch result{
						case .success(let file):
							defer {
								file.stopAccessingSecurityScopedResource()
							}
#if DEBUG
							print(file)
#endif
							
							if file.startAccessingSecurityScopedResource() {
								manager.saveSound(url: file)
							}else{
#if DEBUG
								print("保存失败")
#endif
								
								
							}
							
						case .failure(let err):
#if DEBUG
							print(err)
#endif
							
						}
					}
					
					Spacer()
				}
			}footer: {
				HStack{
					Text(String(localized:  "请先将铃声"))
					Button{
						
						manager.webUrl = BaseConfig.musicUrl
						manager.fullPage = .web
					}label: {
						Text(String(localized: "转换成 caf 格式"))
							.font(.footnote)
					}
					Text(String(localized: ",时长不超过 30 秒。"))
				}
			}
			
			
			Section{
				ForEach(manager.defaultSounds, id: \.self) { url in
					RingtoneItemView(audio: url)
				}
			}header: {
				Text(String(localized:  "自带铃声"))
			}
			
			
		}
	}
}

#Preview {
	RingtongView()
		.environmentObject(PushbackManager.shared)
	
}
