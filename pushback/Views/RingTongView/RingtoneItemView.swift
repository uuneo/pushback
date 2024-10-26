//
//  RingtoneItemView.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import SwiftUI
import AVKit
import Defaults


struct RingtoneItemView: View {
	@EnvironmentObject private var manager:PushBackManager
    var audio:URL
    @State var duration:Double = 0.0
	@Default(.sound) var sound
	@State private var title:String?
    
	var name:String{
		audio.deletingPathExtension().lastPathComponent
	}
    
    var selectSound:Bool{
        sound == audio.deletingPathExtension().lastPathComponent
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
					self.playAudio()
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
                if duration <= 30{
                    Image(systemName: "doc.on.doc")
						.symbolRenderingMode(.palette)
						.foregroundStyle( .tint, Color.primary)
                        .onTapGesture {
                            UIPasteboard.general.string = self.name
							Toast.shared.present(title: String(localized:  "复制成功"), symbol: "document.on.document")
                        }
                }else{
                    Text(String(localized: "长度不能超过30秒"))
                        .foregroundStyle(.red)
                }
                
            }
            
            
            
            
            
        }
        .swipeActions(edge: .leading) {
            Button {
                sound = audio.deletingPathExtension().lastPathComponent
				self.playAudio()
            } label: {
                Text("选择")
            }
            
        }
        
        .task {
            do {
                self.duration =  try await loadVideoDuration(fromURL: self.audio)
            } catch {
#if DEBUG
                print("Error loading video duration: \(error.localizedDescription)")
#endif
                
            }
        }.navigationTitle(String(localized: "所有铃声"))
        
        
    }
	
	private func playAudio(){
		debugPrint("url",audio)
		var soundID: SystemSoundID = 0
		AudioServicesCreateSystemSoundID(audio as CFURL, &soundID)
		AudioServicesPlaySystemSoundWithCompletion(soundID) {
			AudioServicesDisposeSystemSoundID(soundID)
		}
	}
	
    
}

extension RingtoneItemView{
	// 定义一个异步函数来加载audio的持续时间
	func loadVideoDuration(fromURL videoURL: URL) async throws -> Double {
		
		let asset =  AVURLAsset(url: videoURL)
		
		// 使用async/await来加载持续时间
		let duration = try await asset.load(.duration)
		
        // 计算并返回持续时间（以秒为单位）
        let durationInSeconds = CMTimeGetSeconds(duration)
        return durationInSeconds
    }
    
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: duration)) ?? ""
    }
    
}

