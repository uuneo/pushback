//
//  ChnageKeyCenterView.swift
//  pushback
//
//  Created by uuneo 2024/10/13.
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
				Text( "恢复KEY")
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
				Text( "输入使用过的key,可以恢复key")
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
		TextField("请输入旧的KEY", text: $keyName)
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
            
            
            AnimatedButton(normal:
                    .init(title: "恢复key", foregroundColor: .white, background: .blue,symbolImage: "pencil.circle"), success:
                    .init(title: "恢复成功", foregroundColor: .white, background: .green,symbolImage: "checkmark.circle"), fail:
                    .init(title: "恢复失败", foregroundColor: .white, background: .red,symbolImage: "xmark.circle"), loadings: [
                        .init(title: "正在恢复中", foregroundColor: .black, background: .cyan)
                    ]) { view in
                        
                        
                        await view.next(.loading(1))
                        
                       
                        
                        if keyName.count > 3{
                            PushbackManager.shared.restore(address: selectServer.url, deviceKey: self.keyName){ success in
                                Task{
                                    if success{
                                        await view.next(.success){
                                            manager.fullPage = .none
                                        }
                                    }else {
                                        await view.next(.fail)
                                    }
                                }
                            }
                            
                        }else{
                            await view.next(.fail)
                            Toast.shared.present(title: String(localized: "字符数小于3"), symbol: .info)
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




