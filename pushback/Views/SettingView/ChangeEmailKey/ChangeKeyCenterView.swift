//
//  ChnageKeyCenterView.swift
//  pushback
//
//  Created by He Cho on 2024/10/13.
//


import SwiftUI
import Defaults

struct ChnageKeyCenterView: View {
	@State private var emailName:String = ""
	@State private var codeNumber:String = ""
	@State private var isCountingDown:Bool = false
	
	@State private var appear = [false, false, false]
	@State private var circleInitialY:CGFloat = CGFloat.zero
	@State private var circleY:CGFloat = CGFloat.zero
	
	@State private var countdown:Int = 180
	@FocusState private var isPhoneFocused: Bool
	@FocusState private var isCodeFocused: Bool
	
	
	@State private var loadingText:String = ""
	
	private let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

	private var filedColor:Color{
		emailName.isValidEmail() ? .blue : .red
	}
	
	@Default(.servers) var servers
	@State private var selectServer:PushServerModal
	@State private var askOTP:Bool = false
	@State private var otpText:String = ""
	
	init(){
		self.selectServer = Defaults[.servers].first!
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			HStack{
				Text(String(localized: "修改Key"))
					.font(.largeTitle).bold()
					.blendMode(.overlay)
					.slideFadeIn(show: appear[0], offset: 30)
					
				Spacer()
			   
			}
			
			HStack{
				
				Spacer()
				
				Picker(selection:  $selectServer) {
					ForEach(servers, id: \.id){item in
						
						Text(item.url.removeHTTPPrefix())
							.minimumScaleFactor(0.5)
							.tag(item)
						
					}
				} label: {
					Label(String(localized: "更改服务器"), systemImage: "pencil")
				}
				.tint(Color.primary)
				.pickerStyle(DefaultPickerStyle())
				
			}
			
			
			
			VStack{
				EmailAdderss()
				
				CodeButton()
			}
			.slideFadeIn(show: appear[2], offset: 10)
			
			Divider()
			
			HStack{
				Text(String(localized: "不知道如何开始? **获取帮助**"))
					.font(.footnote)
					.foregroundColor(.primary.opacity(0.7))
					.accentColor(.primary.opacity(0.7))
					.onTapGesture {
						// MARK: - 打开web页面
					}
				Spacer()
				if self.countdown != 180{
					Button(action: {
						self.countdown = 0
						self.codeNumber = ""
						self.isCodeFocused = false
						self.isCountingDown = false
			
					}) {
						Text(String(localized: "**重试**"))
					}
				}
				
	 
			}
			
		}
		.coordinateSpace(name: "stack")
		.padding(20)
		.padding(.vertical, 20)
		.background(.ultraThinMaterial)
		.cornerRadius(30)
		.background(
			VStack {
				Circle().fill(.blue).frame(width: 68, height: 68)
					.offset(x: 0, y: circleY)
					.scaleEffect(appear[0] ? 1 : 0.1)
			}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		)
		.modifier(OutlineModifier(cornerRadius: 30))
		.onAppear { animate() }
		.onChange(of: isCountingDown) { value in
			if value{
//				self.startCountdown()
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					self.isPhoneFocused.toggle()
					self.isCodeFocused.toggle()
				}
			}
		}
		.sheet(isPresented: $askOTP){
			OTPView(otpText: $otpText)
				.presentationDetents([.height(350)])
//				.presentationCornerRadius(30)
				.background(
					CircleView()
					
				)
	
		}
		

	}
	
	@ViewBuilder
	func CircleView() -> some View {
		Circle()
			.fill(.linearGradient(colors: [.appYellow, .orange, .red], startPoint: .top, endPoint: .bottom))
			.frame(width: 200, height: 200)
			/// Moving When the Signup Pages Loads/Dismisses
			.offset(x: 90, y: -90 )
			.blur(radius: 15)
			.vSpacing(.top)
	}
	
	
	@ViewBuilder
	func EmailAdderss()-> some View{
		TextField(String(localized: "请输入邮件地址"), text: $emailName)
			.textContentType(.flightNumber)
			.keyboardType(.emailAddress)
			.autocapitalization(.none)
			.disableAutocorrection(true)
			.foregroundStyle(.textBlack)
			.customField(
				icon: "envelope.fill"
			)
			.foregroundStyle(filedColor)
			.overlay(
				GeometryReader { proxy in
					let offset = proxy.frame(in: .named("stack")).minY + 32
					Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
					
				}
					.onPreferenceChange(CirclePreferenceKey.self) { value in
						circleInitialY = value
						circleY = value
					}
			)
			.focused($isPhoneFocused)
			.onChange(of: isPhoneFocused) { value in
				if value {
					withAnimation {
						circleY = circleInitialY
					}
				}
			}
			.onTapGesture {
				self.isPhoneFocused = true
			}
			.disabled(isCountingDown)
	}
	
	
	@ViewBuilder
	private func CodeButton()-> some View{
		VStack{
			GradientButton(title: "获取验证码", icon: "arrow.right.circle.dotted") {
				self.askOTP.toggle()
				
				
			}

		}.padding()
		
	}
	
	
	
	
	func animate() {
		withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.2)) {
			appear[0] = true
		}
		withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.4)) {
			appear[1] = true
		}
		withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8).delay(0.6)) {
			appear[2] = true
		}
	}
	
	func sendCode(_ email:String) async -> (Bool,String?) {
		return (false, "")
	}
	
	func register(email:String, code:String) async -> (Bool,String?) {
		return (false, "")
	}
}

#Preview {
	ChnageKeyCenterView()
}




