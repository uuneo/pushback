//
//  AnswerVoiceView.swift
//  pushme
//
//  Created by lynn on 2025/6/18.
//

import SwiftUI


struct AnswerVoiceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateWave = false
    @State private var callUser:CallUser
    
    @State private var answered:Bool = false
    
    init(answer: CallUser) {
        self._callUser = State(wrappedValue: answer)
    }
    
    @State private var configButton = SlideToConfirm.Config(
        idleText: "接听来电...",
        onSwipeText: "确认接听",
        confirmationText: "正在接通",
        tint: .green,
        foregorundColor: .white
    )
    
    var body: some View {
        ZStack {
            Color(red: 200/255, green: 29/255, blue: 70/255)
                .ignoresSafeArea()
            VStack {
                Spacer()
                callerAvatar()
                Spacer()
                nameAndPhoneNumber()
                Spacer()
                
                ZStack{
                    
                    HStack(spacing: 40) {
                        
                        CircleButton(icon: "mic.fill", bgColor: Color.white, iconColor: Color(red: 24/255, green: 29/255, blue: 70/255))
                            .offset(x: !answered ? -60 : 0)
                        
                        CircleButton(icon: "phone.down.fill", bgColor: !answered ? Color.green : Color.red){
                            let manager = WebRtcManager.shared
                            manager.endCall()
                            self.dismiss()
                        } .rotationEffect(.degrees(!answered ? 180 : 0))
                        
                        CircleButton(icon: "speaker.wave.3.fill", bgColor: Color.white,iconColor: Color(red: 24/255, green: 29/255, blue: 70/255))
                            .offset(x: !answered ? 60 : 0)
                    }
                    .opacity(!answered ? 0 : 1)
                    
                    SlideToConfirm(config: configButton, disabled: true) {
                        print("Swiped!")
                        Task.detached(priority: .userInitiated) {
                            let manager = WebRtcManager.shared
                            await manager.answerCall(callUser: callUser)
                            DispatchQueue.main.asyncAfter(deadline: .now()){
                                self.answered = true
                            }
                            
                        }
                        
                    }
                    .opacity(answered ? 0 : 1)
                    .scaleEffect(x: answered ? 0.8 : 1 )
                    
                }
                .padding(.bottom, 60)
                .animation(.easeInOut, value: answered)
                
               
                
                
            }
        }
    }
    
    @ViewBuilder
    func callerAvatar() -> some View{
        ZStack {
            // 电波特效
            ForEach(0..<3) { k in
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: CGFloat(160 + k*60), height: CGFloat(180 + k*60))
                    .scaleEffect(animateWave ? 1.15 : 0.9)
                    .opacity(animateWave ? 0.2 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(k) * 0.2), value: animateWave)
            }
            // 头像
            Group{
                if let avatar = callUser.avatar, let uiimage = UIImage(contentsOfFile: avatar.path()){
                    
                    Image(uiImage: uiimage)
                        .resizable()
                    
                }else{
                    if !callUser.name.isEmpty, let data = callUser.name.avatarImage() {
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
            .VButton()
        }
        .frame(height: 320)
        .onAppear {
            animateWave = true
        }
    }
    
    
    @ViewBuilder
    func nameAndPhoneNumber()-> some View{
        VStack(spacing: 12) {
            Group{
                if !callUser.name.isEmpty{
                    Text(verbatim: callUser.name)
                }else{
                    Text("未知用户")
                }
                
            }
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.white)
            
            Group{
                Text("获取用户信息中...")
            }
            .font(.system(size: 20, weight: .regular))
            .foregroundColor(Color.white)
        }
    }
}
