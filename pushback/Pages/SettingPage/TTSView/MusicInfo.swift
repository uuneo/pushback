//
//  MusicInfo.swift
//  AppleMusicBottomSheet
//
//  Created by Balaji on 18/03/23.
//

import SwiftUI


/// Resuable File
struct MusicInfo: View {
    @EnvironmentObject private var audioManager:AudioManager
    @State private var progress: CGFloat = 0
    @State private var duration: TimeInterval = 0
    
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying: Bool = false
   
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            if let audioUrl = audioManager.ShareURL{
                ShareLink(item: audioUrl, preview: SharePreview("pushback.mp3")){
                    Image(systemName: "display.and.arrow.down")
                }.simultaneousGesture(
                    TapGesture()
                        .onEnded({ _ in
                            audioManager.speakPlayer?.pause()
                        })
                )
            }
          
            /// Adding Matched Geometry Effect (Hero Animation
            VStack{
                Spacer()
                GeometryReader { proxy in
                    let width = proxy.size.width
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .frame(height: 5)
                        
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: safeFrameWidth(progress: progress, width: width), height: 5)
                    }
                    .contentShape(Rectangle()) // 扩大手势区域
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newProgress = max(0, min(value.location.x / width, 1))
                                progress = newProgress
                            }
                            .onEnded({ _ in
                                if let player = audioManager.speakPlayer{
                                    player.currentTime = duration *  progress
                                    player.play()
                                }
                            })
                    )
                    .environment(\.colorScheme, .light)
                }
                .frame(height: 10)
                
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer(minLength: 0)
                    
                    Text(formatTime(duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }.padding(.bottom, 5)
            }.padding(.leading, 10)
                .padding(.trailing)
            
            
            Spacer(minLength: 0)
            
            HStack{
                Button {
                    if let player = audioManager.speakPlayer{
                        
                        if isPlaying{
                            player.pause()
                        }else{
                            player.play()
                        }
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                
                
                Button {
                    audioManager.speakPlayer?.stop()
                    audioManager.speaking.toggle()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .padding(.leading, 25)
            }
            .if(audioManager.loading) { view in
                ProgressView()
            }
            
        }
    
        .foregroundColor(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onReceive(timer) { _ in
            if let player = audioManager.speakPlayer {
                currentTime = player.currentTime
                progress =  currentTime / duration
                self.isPlaying = player.isPlaying
            }
        }
        .onChange(of: audioManager.speakPlayer) { player in
            if let player = player{
                self.duration = player.duration
            }
        }
    }
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    
    func safeFrameWidth(progress: CGFloat, width: CGFloat) -> CGFloat {
        guard progress.isFinite, width.isFinite, width > 0 else { return 0.1 }
        let value = abs(progress * width)
        return min(max(value, 0.1), width)
    }
}

