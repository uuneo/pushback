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
	@State private var soundID:SystemSoundID = 0
	var body: some View {
		NavigationStack{
			List {
				
				
				Section {
					HStack{
						Spacer()
						Button {
							self.showUpload.toggle()
	#if DEBUG
							print("上传铃声")
	#endif
							
							
						} label: {
							Label("上传铃声", systemImage: "waveform" )
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
				}header: {
					Spacer()
				}footer: {
					HStack{
						Text( "请先将铃声")
						Button{
							
							manager.webUrl = BaseConfig.musicUrl
							manager.fullPage = .web
						}label: {
							Text( "转换成 caf 格式")
								.font(.footnote)
						}
						Text( ",时长不超过 30 秒。")
					}
				}
				
				if manager.customSounds.count > 0{
					Section{
						
						
						
						ForEach(manager.customSounds, id: \.self) { url in
							RingtoneItemView(audio: url, ringType: .custom)
							
						}.onDelete { indexSet in
							for index in indexSet{
								manager.deleteSound(url: manager.customSounds[index])
							}
						}
					}header: {
						Text(  "自定义铃声")
					}
				}
				
				
				Section{
					ForEach(manager.defaultSounds, id: \.self) { url in
						RingtoneItemView(audio: url, ringType: .local)
					}
				}header: {
					Text(  "自带铃声")
				}
				
				
			}
			.navigationTitle("所有铃声")
			.toolbar {
				
				ToolbarItem {
					
					NavigationLink {
						CloudRingTongsView()
					} label: {
						Label("云音", systemImage: "icloud.and.arrow.down")
					}

				}
			}
		}
		
	}
	
	
	
	
	

	
}

#Preview {
	RingtongView()
		.environmentObject(PushbackManager.shared)
	
}

