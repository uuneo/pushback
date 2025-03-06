//
//  SoundView.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import SwiftUI
import AVFoundation
import UIKit

struct SoundView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var audioManager = AudioManager.shared
	@State private var showUpload:Bool = false
	var body: some View {
		NavigationStack{
			List {


				Section {
					HStack{
						Spacer()
						Button {
							self.showUpload.toggle()
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
									if file.startAccessingSecurityScopedResource() {
										audioManager.saveSound(url: file)
									}

								case .failure(let err):
									Log.debug(err)

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
							PushbackManager.shared.fullPage = .web(BaseConfig.musicUrl)
						}label: {
							Text( "转换成 caf 格式")
								.font(.footnote)
						}
						Text( ",时长不超过 30 秒。")
					}
				}

				if audioManager.customSounds.count > 0{
					Section{



						ForEach(audioManager.customSounds, id: \.self) { url in
							SoundItemView(audio: url, ringType: .custom)
						}.onDelete { indexSet in
							for index in indexSet{
								audioManager.deleteSound(url: audioManager.customSounds[index])
							}
						}
					}header: {
						Text(  "自定义铃声")
					}
				}


				Section{
					ForEach(audioManager.defaultSounds, id: \.self) { url in
						SoundItemView(audio: url, ringType: .local)
					}
				}header: {
					Text(  "自带铃声")
				}


			}
			.navigationTitle("所有铃声")
			.onDisappear{
				audioManager.playAudio(url: nil)
			}
		}

	}







}

#Preview {
	SoundView()
		.environmentObject(PushbackManager.shared)

}

