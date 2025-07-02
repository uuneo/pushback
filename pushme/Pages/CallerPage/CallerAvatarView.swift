//
//  CallerAvatarView.swift
//  pushme
//
//  Created by lynn on 2025/6/25.
//
import SwiftUI


struct CallerAvatarView: View {
    var callUser:CallUser?
    @Binding var audioLevel: CGFloat
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            VoiceBlobViewRepresentable(
                maxLevel: 50.0,
                smallBlobRange: (min: 0.40, max: 0.54),
                mediumBlobRange: (min: 0.52, max: 0.79),
                bigBlobRange: (min: 0.55, max: 1.0),
                audioLevel: $audioLevel,
                isAnimating: $isAnimating,
                color: .systemGreen
            )
            .frame(width: 220, height: 220)
            // 头像
            Group{
                if let avatar = callUser?.avatar, let uiimage = UIImage(contentsOfFile: avatar.path()){
                    
                    Image(uiImage: uiimage)
                        .resizable()
                    
                }else{
                    if let name = callUser?.name, let data = name.avatarImage() {
                        Image(uiImage: data)
                            .resizable()
                    }else{
                        Image("logo")
                            .resizable()
                    }
                    
                }
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .shadow(radius: 8)
           
        }
        .frame(height: 320)
        .VButton( onRelease: {_ in
            withAnimation {
                self.audioLevel = CGFloat(Int.random(in: 20...50))
            }
            return false
        })
    }
}


#Preview{
    DialCallView(phoneNumber: "100")
}
