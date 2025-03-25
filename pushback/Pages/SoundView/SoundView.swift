//
//  SoundView.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import SwiftUI
import AVFoundation
import UIKit

struct SoundView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var audioManager = AudioManager.shared
	@State private var showUpload:Bool = false

	var body: some View {
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
                    
                   
                ///  UTType.types(tag: "caf", tagClass: UTTagClass.filenameExtension,conformingTo: nil)
                    .fileImporter(isPresented: $showUpload, allowedContentTypes: [.audio] ) { result in
                      
                        switch result{
                            case .success(let file):
                            
                                defer {
                                    file.stopAccessingSecurityScopedResource()
                                }
                                if file.startAccessingSecurityScopedResource() {
                                    
                                    if file.pathExtension.lowercased() == "caf"{
                                        audioManager.saveSound(url: file)
                                        return
                                    }
                                    
                                    let fileName = file.deletingPathExtension().lastPathComponent
                                  
                                    let data = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).caf")
                                    audioManager.convertAudioToCAF(inputURL: file, outputURL: data) { result in
                                        switch result {
                                        case .success(let success):
                                            Log.debug(success)
                                            audioManager.saveSound(url: success)
                                        case .failure(let failure):
                                            Log.error(failure)
                                        }
                                    }
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

#Preview {
	SoundView()
		.environmentObject(PushbackManager.shared)

}

