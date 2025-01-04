//
//  ChnageKeyCenterView.swift
//  pushback
//
//  Created by He Cho on 2024/10/13.
//


import SwiftUI
import Defaults

struct ChnageKeyCenterView: View {
	@EnvironmentObject private var manager:PushbackManager
	@EnvironmentObject private var store:AppState

	@State private var keyName:String = ""
	
	@State private var appear = [false, false, false]
	@State private var circleInitialY:CGFloat = CGFloat.zero
	@State private var circleY:CGFloat = CGFloat.zero
	
	@Default(.servers) var servers
	@State private var selectServer:PushServerModel
	
	@FocusState private var isPhoneFocused
	
	init(){
		self.selectServer = Defaults[.servers].first!
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			HStack{
				Text( "修改Key")
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
					Label("更改服务器", systemImage: "pencil")
				}
				.tint(Color.primary)
				.pickerStyle(DefaultPickerStyle())

			}
			
			
			
			VStack{
				InputKey()
				
				CodeButton()
					
			}
			.slideFadeIn(show: appear[2], offset: 10)
			
			Divider()
			
			HStack{
				Text( "如果太简单，会有收到垃圾信息的风险！")
					.font(.footnote)
					.foregroundColor(.primary.opacity(0.7))
					.accentColor(.primary.opacity(0.7))

				Spacer()
				
	 
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

		

	}
	
	@ViewBuilder
	func InputKey()-> some View{
		TextField("请输入自定义推送Key", text: $keyName)
			.textContentType(.flightNumber)
			.keyboardType(.emailAddress)
			.autocapitalization(.none)
			.disableAutocorrection(true)
			.foregroundStyle(.textBlack)
			.customField(
				icon: "envelope.fill"
			)
			.overlay(
				GeometryReader { proxy in
					let offset = proxy.frame(in: .named("stack")).minY + 32
					Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
					
				}.onPreferenceChange(CirclePreferenceKey.self) { value in
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
	}
	
	
	@ViewBuilder
	private func CodeButton()-> some View{
		VStack{
			AngularButton(title: String(localized: "修改Key")) {
				if !selectServer.url.isInsideServer() || store.subscriptionInfo.canAccessContent{
					if keyName.count > 3{
						// TODO: - 修改key
						Task.detached {
							let success = await PushbackManager.shared.changeKey(server: selectServer, newKey: self.keyName)

							if success{
								await MainActor.run {
									manager.fullPage = .none
								}
							}
						}
					}else{
						Toast.shared.present(title: String(localized: "字符数小于3"), symbol: .info)
					}
				}else{
					Toast.shared.present(title: String(localized: "没有权限,需自建服务器"), symbol: .info)
				}

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




