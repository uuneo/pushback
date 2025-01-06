//
//  SoundItemView.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import SwiftUI
import AVKit
import Defaults



struct SoundItemView: View {
	@StateObject private var audioManager = AudioManager.shared
	@Default(.sound) var sound

	var audio:URL
	var fileName:String?
	var ringType:SoundModel.sType = .local
    @State var duration:Double = 0.0
	@State private var title:String?
	var name:String{
		ringType == .cloud ? (fileName ?? "") : audio.deletingPathExtension().lastPathComponent
	}
    
    var selectSound:Bool{
		sound.name == audio.deletingPathExtension().lastPathComponent && ringType == sound.type
    }
	


    var body: some View{
        HStack{
            
            HStack{
                if selectSound{
                    Image(systemName: "checkmark.circle")
                        .frame(width: 35)
                        .foregroundStyle(Color.green)
                }
                
                Button{
					audioManager.playAudio(url: audio)
                }label: {
					VStack(alignment: .leading){
						Text( name)
							.foregroundStyle(Color.textBlack)
						Text("\(formatDuration(duration))s")
							.font(.caption)
							.foregroundStyle(.gray)
					}
                }
            }
            
            
            
            
            HStack{
                Spacer()
				if ringType == .cloud{
					Image(systemName: "square.and.arrow.down.on.square")
						.symbolRenderingMode(.palette)
						.foregroundStyle( .tint, Color.primary)
						.onTapGesture {
							if let fileName{
								audioManager.saveSound(url: audio,name: "\(fileName).caf")
							}
							
						}
				}else{
					if duration <= 30{
						Image(systemName: "doc.on.doc")
							.symbolRenderingMode(.palette)
							.foregroundStyle( .tint, Color.primary)
							.onTapGesture {
								UIPasteboard.general.string = self.name
								Toast.shared.present(title: String(localized:  "复制成功"), symbol: "document.on.document")
							}
					}else{
						Text("长度不能超过30秒")
							.foregroundStyle(.red)
					}
					
				}
               
            }
            
            
            
            
            
        }
        .swipeActions(edge: .leading) {
			if ringType == .cloud{
				Image(systemName: "square.and.arrow.down.on.square")
					.symbolRenderingMode(.palette)
					.foregroundStyle( .tint, Color.primary)
					.onTapGesture {
						audioManager.saveSound(url: audio,name: fileName)
					}
			}else{
				Button {
					sound = .init(type: ringType, name: audio.deletingPathExtension().lastPathComponent)
					audioManager.playAudio(url: audio)
				} label: {
					Text("设置")
				}.tint(.green)
			}
          
        }
        .task {
            do {
                self.duration =  try await loadVideoDuration(fromURL: self.audio)
            } catch {
#if DEBUG
                print("Error loading aideo duration: \(error.localizedDescription)")
#endif
                
            }
        }
	
        
        
    }

	
}

extension SoundItemView{
	// 定义一个异步函数来加载audio的持续时间
	func loadVideoDuration(fromURL audioURL: URL) async throws -> Double {
		return try AVAudioPlayer(contentsOf: audioURL).duration
    }
    
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: duration)) ?? ""
    }
    
}






#Preview{
	SettingsView()
		.environmentObject(PushbackManager.shared)
}
