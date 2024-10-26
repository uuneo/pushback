//
//  OTPVerificationView.swift
//  AutoOtpTF
//
//  Created by Balaji on 23/12/22.
//

import SwiftUI

struct OTPVerificationView: View {
    /// - View Properties
    @Binding var otpText: String
    /// - Keyboard State
    @FocusState private var isKeyboardShowing: Bool
    var body: some View {
        HStack(spacing: 0){
            /// - OTP Text Boxes
            /// Change Count Based on your OTP Text Size
            ForEach(0..<6,id: \.self){index in
                OTPTextBox(index)
            }
        }
        .background(content: {
            TextField("", text: $otpText.limit(6))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                /// - Hiding it Out
                .frame(width: 1, height: 1)
                .opacity(0.001)
                .blendMode(.screen)
                .focused($isKeyboardShowing)
        })
        .contentShape(Rectangle())
        /// - Opening Keyboard When Tapped
        .onTapGesture {
            isKeyboardShowing = true
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
				Button(String(localized: "关闭键盘")){
					
                    isKeyboardShowing = false
                }
                .tint(.appYellow)
                .fontWeight(.heavy)
                .hSpacing(.trailing)
            }
        }
    }
    
    // MARK: OTP Text Box
    @ViewBuilder
    func OTPTextBox(_ index: Int)->some View{
        ZStack{
            if otpText.count > index{
                /// - Finding Char At Index
                let startIndex = otpText.startIndex
                let charIndex = otpText.index(startIndex, offsetBy: index)
                let charToString = String(otpText[charIndex])
                Text(charToString)
            }
        }
        .frame(width: 45, height: 45)
        .background {
            /// - Highlighting Current Active Box
            let status = (isKeyboardShowing && otpText.count == index)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(status ? .appYellow : Color.gray,lineWidth: status ? 3 : 0.5)
                /// - Adding Animation
                .animation(.easeInOut(duration: 0.2), value: isKeyboardShowing)
        }
        .frame(maxWidth: .infinity)
    }
	
	
}

// MARK: Binding <String> Extension
extension Binding where Value == String{
	func limit(_ length: Int)->Self{
		DispatchQueue.main.async {
			var data = self.wrappedValue
			// 先去掉空格和 / 符号
			data = data.replacingOccurrences(of: " ", with: "")
			data = data.replacingOccurrences(of: "/", with: "")
			
			// 如果字符串长度超过限制，则截取前n个字符
			if data.count > length {
				data = String(data.prefix(length))
			}
			// 更新 wrappedValue
			self.wrappedValue = data
		}
		return self
	}
}


/// Custom SwiftUI View Extensions
extension View {
	/// View Alignments
	@ViewBuilder
	func hSpacing(_ alignment: Alignment = .center) -> some View {
		self
			.frame(maxWidth: .infinity, alignment: alignment)
	}
	
	@ViewBuilder
	func vSpacing(_ alignment: Alignment = .center) -> some View {
		self
			.frame(maxHeight: .infinity, alignment: alignment)
	}
	
	/// Disable With Opacity
	@ViewBuilder
	func disableWithOpacity(_ condition: Bool) -> some View {
		self
			.disabled(condition)
			.opacity(condition ? 0.5 : 1)
	}
}
