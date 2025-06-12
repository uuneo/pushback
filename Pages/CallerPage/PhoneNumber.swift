//
//  PhoneNumber.swift
//  pushme
//
//  Created by lynn on 2025/6/12.
//

import SwiftUI
import Defaults

struct PhoneNumberInputView: View {
    @EnvironmentObject private var manager:AppManager
    @Default(.user) var user
    @State private var phoneNumber: String = ""
    
    let numberPad: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "#", "0", "X"]
    let columns = [ GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()) ]
    
    var numberOK:Bool{
        phoneNumber.starts(with: "#") ? phoneNumber.count < 4 : phoneNumber.count < 3
    }
    
    var body: some View {
        VStack(spacing: 32) {
    
            VStack(spacing: 8) {
                
                HStack{
                    Text("本机：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(user.caller)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                       
                }
                .VButton(onRelease: {_ in
                    manager.router.append(.deviceInfo)
                    return true
                })
                
                Text("输入 \(BaseConfig.AppName) 用户ID")
                    .font(.subheadline)
                    .foregroundColor(.gray)
               
                Text(phoneNumber)
                    .font(.title)
                    .fontWeight(.medium)
                    .padding(.bottom, 4)
                    .frame(minHeight: 30)
                    .onChange(of: phoneNumber) {value in
                        if value.first == "0" {
                            phoneNumber.removeFirst()
                        } else if value.starts(with: "#0") {
                            phoneNumber.remove(at: value.index(phoneNumber.startIndex, offsetBy: 1))
                        }
                    }
            }
            
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(numberPad, id: \.self) { value in
                    Button{
                        handleInput(value)
                        AudioManager.playNumber(number: value == "#" ? "11" : value)
                    }label: {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .shadow(color: Color.primary.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            if value == "X" {
                                Image(systemName: "delete.backward")
                                    .font(.title)
                                    .foregroundStyle(phoneNumber.isEmpty ? .gray : .red)
                            } else {
                                Text(value)
                                    .font(.largeTitle)
                                    
                            }
                        }
                        .frame(width: 80, height: 80)
                    }
                    .tint(.primary)
                    .disabled(value == "X" && phoneNumber.isEmpty)
                    .disabled(value == "#" && phoneNumber.count >= 1)
                    .disabled(value == "0" && (phoneNumber.count == 0 || phoneNumber == "#") )
      
                }
            }
            .padding(.horizontal, 32)
            
            
            HStack(spacing: 48) {
                Spacer()
                Button{
                    Haptic.impact()
                    AppManager.shared.fullPage = .call(phoneNumber)
                    
                } label: {
                    ZStack {
                        Circle()
                            .fill(numberOK ? .red : Color.blue)
                            .frame(width: 72, height: 72)
                            
                        Circle()
                            .stroke(Color.primary.gradient, lineWidth: 6)
                            .frame(width: 72, height: 72)
                            
                        Image(systemName: "phone.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                }
                Spacer()
            }
            .padding(.top)
            .padding(.bottom, 60)
            .disabled(numberOK)
            .animation(.easeInOut, value: numberOK)
            
        }
    }

    
    private func handleInput(_ value: String) {
        if value == "X" {
            if !phoneNumber.isEmpty {
                phoneNumber.removeLast()
                Haptic.impact()
            }
        } else if value != "" && phoneNumber.count < 15 {
            phoneNumber.append(value)
            Haptic.impact()
        }
    }
    
    
    
}


#Preview {
    PhoneNumberInputView()
}
