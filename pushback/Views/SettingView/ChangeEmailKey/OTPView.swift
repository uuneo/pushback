//
//  OTPView.swift
//  LoginKit
//
//  Created by Balaji on 04/08/23.
//

import SwiftUI

struct OTPView: View {
    @Binding var otpText: String
    /// Environment Properties
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 15, content: {
            /// Back Button
            Button(action: {
                dismiss()
				otpText = ""
            }, label: {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundStyle(.gray)
            })
            .padding(.top, 15)
            
            Text("输入验证码")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.top, 5)
            
			Text(String(localized: "一个6位数的代码已发送到您的邮箱"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
                .padding(.top, -5)
            
            VStack(spacing: 25) {
                /// Custom OTP TextField
                OTPVerificationView(otpText: $otpText)
                
				
                /// SignUp Button
				GradientButton(title: String(localized: "修改Key"), icon: "arrow.right.circle.dotted") {
                    /// YOUR CODE
                }
                .hSpacing(.trailing)
                /// Disabling Until the Data is Entered
                .disableWithOpacity(otpText.isEmpty)
            }
            .padding(.top, 20)
            
            Spacer(minLength: 0)
        })
        .padding(.vertical, 15)
        .padding(.horizontal, 25)
        /// Since this is going to be a Sheet.
        .interactiveDismissDisabled()
    }
}


struct GradientButton: View {
	var title: String
	var icon: String
	var onClick: () -> ()
	var body: some View {
		Button(action: onClick, label: {
			HStack(spacing: 15) {
				Text(title)
				Image(systemName: icon)
					.symbolRenderingMode(.palette)
					.foregroundStyle(Color.primary, .black)
			}
			.fontWeight(.bold)
			.foregroundStyle(.white)
			.padding(.vertical, 12)
			.padding(.horizontal, 35)
			.background(.linearGradient(colors: [.appYellow, .orange, .red], startPoint: .top, endPoint: .bottom), in: .capsule)
			
		})
	}
}

#Preview {
    ContentView()
}
