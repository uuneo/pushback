//
//  CallingView.swift
//  pushme
//
//  Created by lynn on 2025/6/15.
//

import SwiftUI

struct DialCallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateWave = false
    @State private var callUser:CallUser? = nil
    @State private var phoneNumber:String
    
    init(phoneNumber: String) {
        self._phoneNumber = State(wrappedValue: phoneNumber)
    }
    let callManager = CallMainManager.shared.manager
    
    var body: some View {
        ZStack {
            Color(red: 25/255, green: 29/255, blue: 70/255)
                .ignoresSafeArea()
            VStack {
                Spacer()
                callerAvatar()
                Spacer()
                nameAndPhoneNumber()
                Spacer()
                HStack(spacing: 40) {
                   
                    CircleButton(icon: "mic.fill", bgColor: Color.white, iconColor: Color(red: 24/255, green: 29/255, blue: 70/255)){
                        Haptic.impact()
                    }
                    CircleButton(icon: "phone.down.fill", bgColor: Color.red){
                        let manager = CallMainManager.shared.manager
                        manager.endCall()
                        Haptic.impact()
                        self.dismiss()
                        AppManager.shared.fullPage = .none
                    }
                    CircleButton(icon: "speaker.wave.3.fill", bgColor: Color.white,iconColor: Color(red: 24/255, green: 29/255, blue: 70/255)){
                        Haptic.impact()
                    }
                }
                .padding(.bottom, 60)
                
                
            }
        }
        .task{  startCallManager(caller: phoneNumber) }
    }
    
    func startCallManager(caller:String){
        Task.detached(priority: .userInitiated) {
            guard let call = await CallCloudManager.shared.queryCaller(caller: caller) else {
                await MainActor.run {
                    AppManager.shared.fullPage = .none
                }
               
                Toast.error(title: "没有找到用户")
                return
            }
            await MainActor.run {
                self.callUser = call
            }
            debugPrint(call)
            do{
                try await callManager.call(uuid: UUID(), callerName: call.name)
            }catch{
                debugPrint(error.localizedDescription)
            }
            
            
        }
    }
    
    @ViewBuilder
    func callerAvatar(avatar: URL? = nil) -> some View{
        ZStack {
            // 电波特效
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: CGFloat(160 + i*60), height: CGFloat(180 + i*60))
                    .scaleEffect(animateWave ? 1.15 : 0.9)
                    .opacity(animateWave ? 0.2 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(i) * 0.2), value: animateWave)
            }
            // 头像
            Group{
                if let caller = callUser,
                   let avatar = caller.avatar,
                   let uiimage = UIImage(contentsOfFile: avatar.path()){
                    
                    Image(uiImage: uiimage)
                        .resizable()
                    
                }else{
                    Image("logo")
                        .resizable()
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
                if let caller = callUser, !caller.name.isEmpty{
                    Text(verbatim: caller.name)
                }else{
                    Text("匿名用户")
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

struct CircleButton: View {
    var icon: String
    var bgColor: Color
    var iconColor: Color = .white
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: 70, height: 70)
                    .shadow(color: bgColor.opacity(0.3), radius: 8, x: 0, y: 4)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(iconColor)
            }
        }
    }
}


#Preview{
    DialCallView(phoneNumber: "100")
}

