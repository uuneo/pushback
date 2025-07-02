//
//  CallingView.swift
//  pushme
//
//  Created by lynn on 2025/6/15.
//

import SwiftUI
import Defaults

struct DialCallView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateWave = false
    @State private var callUser:CallUser? = nil
    @State private var phoneNumber:String
    @State private var audioLevel: CGFloat = 50
    @State private var isAnimating: Bool = true
    
    init(phoneNumber: String) {
        self._phoneNumber = State(wrappedValue: phoneNumber)
    }
    let callManager = WebRtcManager.shared

    var body: some View {
        ZStack {
            Color(red: 25/255, green: 29/255, blue: 70/255)
                .ignoresSafeArea()
            VStack {
                
                Spacer()
               
                CallerAvatarView(callUser: callUser, audioLevel: $audioLevel, isAnimating: $isAnimating)
                Spacer()
                nameAndPhoneNumber()
                Spacer()
                HStack(spacing: 40) {
                   
                    CircleButton(icon: "mic.fill", bgColor: Color.white, iconColor: Color(red: 24/255, green: 29/255, blue: 70/255)){
                        Haptic.impact()
                    }
                    CircleButton(icon: "phone.down.fill", bgColor: Color.red){
                        
                        callManager.endCall()
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
                WebRtcManager.shared.remoteCallUser = call
            }
            do{
                try await callManager.setupPeerConnection(id: "43f96a3bb057238c2ef897cdac42b16b",
                                         token: "6b50e52b2198830b090ca3cd63576fd4803f71504534fab1ed985616d8df3d43")
            }catch{
                debugPrint(error.localizedDescription)
                await MainActor.run {
                    AppManager.shared.fullPage = .none
                }
            }
            
            let id = Defaults[.id]
            
           let success = await ApnsManager.shared.voip(deviceToken: call.voipToken, remoteUserId: id)
           
            await MainActor.run {
                self.callUser = call
            }
            
            do{
                try await callManager.call(uuid: UUID(), callerName: call.name)
            }catch{
                debugPrint(error.localizedDescription)
            }
            
            
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
    DialCallView(phoneNumber: "101")
}

