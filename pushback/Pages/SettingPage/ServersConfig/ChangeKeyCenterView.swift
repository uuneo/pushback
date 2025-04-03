//
//  ChnageKeyCenterView.swift
//  pushback
//
//  Created by uuneo 2024/10/13.
//


import SwiftUI
import Defaults


struct ChangeKeyCenterView: View {
	@EnvironmentObject private var manager:PushbackManager
	@EnvironmentObject private var store:AppState

    @State private var keyName:String = ""
	@State private var keyHost:String = ""
    
    @State private var disabledPage:Bool = false
    
    var pageTitle:String{
        keyName.isEmpty ? String(localized: "注册KEY") : String(localized: "恢复KEY")
    }
	
	@State private var appear = [false, false, false]
	@State private var circleInitialY:CGFloat = CGFloat.zero
	@State private var circleY:CGFloat = CGFloat.zero
	
	@Default(.servers) var servers
	
    @FocusState private var isPhoneFocused
	@FocusState private var isHostFocused
    
    var serversSelect:[PushServerModel]{
        servers.reduce(into: [PushServerModel]()) { result, item in
            if !result.contains(where: {$0.url == item.url}){
                result.append(item)
            }
       }
    }
    
    var dismiss:() -> Void
    
    @State private var buttonState:AnimatedButton.buttonState = .normal
	
	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			HStack{
				Text( pageTitle )
					.font(.largeTitle).bold()
					.blendMode(.overlay)
					.slideFadeIn(show: appear[0], offset: 30)
                    
				Spacer()
			   
			}
            
			
			HStack{
				
				Spacer()
				
                
                Menu{
                    ForEach(serversSelect, id: \.id){item in
                        
                        Button{
                            self.keyHost = item.url
                            PushbackManager.vibration(style: .medium)
                        }label:{
                            Text(item.url.removeHTTPPrefix())
                                .minimumScaleFactor(0.5)
                        }
                    }
                }label: {
                    HStack{
                        Image(systemName: "filemenu.and.selection")
                            .imageScale(.medium)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .primary)

                        Text("选择服务器")
                           
                           
                    }.padding(.trailing)
                       
                }
                .foregroundColor(.primary)
                .blendMode(.overlay)
			}
			
			
			
			VStack{
				
                InputHost()
                
                InputKey()
                
                
                registerButton()
                    .if(!keyName.isEmpty) { _ in
                        recoverButton()
                    }
                    .transition(.opacity.combined(with: .scale).animation(.easeInOut(duration: 0.5)))
                
					
			}
			.slideFadeIn(show: appear[2], offset: 10)
			
			Divider()
			
			HStack{
				Text( "输入旧key,可以恢复")
                    .font(.footnote.bold())
					.foregroundColor(.primary.opacity(0.7))
					.accentColor(.primary.opacity(0.7))

				Spacer()
				
                Text( "服务器部署教程")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                    .onTapGesture {
                        manager.fullPage = .web(BaseConfig.delpoydoc)
                    }
	 
			}

		}
		.coordinateSpace(name: "stack")
		.padding(20)
		.padding(.vertical, 10)
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
        .disabled(disabledPage)
		

	}
    
    @ViewBuilder
    func InputHost()-> some View{
        TextField("请输入URL", text: $keyHost)
            .textContentType(.flightNumber)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .foregroundStyle(.textBlack)
            .customField(
                icon: "personalhotspot.circle"
            ){
                
            }
            .overlay(
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("stack")).minY + 32
                    Color.clear.preference(key: CirclePreferenceKey.self, value: offset)
                    
                }.onPreferenceChange(CirclePreferenceKey.self) { value in
                    circleInitialY = value
                    circleY = value
                }
            )
            .focused($isHostFocused)
            .onChange(of: isHostFocused) { value in
                if value {
                    withAnimation {
                        circleY = circleInitialY
                    }
                }
            }
            .onTapGesture {
                self.isHostFocused = true
            }
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
				icon: "person.badge.key"
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
	private func recoverButton()-> some View{
		VStack{
            
            
            AnimatedButton(state:$buttonState, normal:
                    .init(title: String(localized: "恢复KEY") , background: .blue,symbolImage: "pencil.circle"), success:
                    .init(title: String(localized: "恢复成功"), background: .green,symbolImage: "checkmark.circle"), fail:
                    .init(title: String(localized: "恢复失败"), background: .red,symbolImage: "xmark.circle"), loadings: [
                        .init(title: String(localized: "检查参数..."), background: .cyan),
                        .init(title: String(localized: "恢复中..."),background: .cyan)
                    ]) { view in
                        
                        DispatchQueue.main.async {
                            self.disabledPage = true
                        }
                        await view.next(.loading(0))
                        
                        DispatchQueue.main.async {
                            self.keyName = keyName.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.keyHost = keyHost.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
                        try? await Task.sleep(for: .seconds(0.5))
                       
                        
                        guard keyHost.isValidURL() == .remote, !keyName.isEmpty else {
                            await view.next(.fail)
                            Toast.info(title: String(localized: "参数错误"))
                            DispatchQueue.main.async {
                                self.disabledPage = false
                            }
                            return
                        }
                        
                       
                        
                        await view.next(.loading(1))
                        
                       
                        
                        PushbackManager.shared.restore(address: keyHost, deviceKey: self.keyName){ success in
                            Task{
                                try? await Task.sleep(for: .seconds(1))
                                if success{
                                   
                                    await view.next(.success){
                                        DispatchQueue.main.async{
                                            self.dismiss()
                                            self.disabledPage = false
                                        }
                                    }
                                }else {
                                    Toast.error(title: String(localized: "key不正确"))
                                    await view.next(.fail)
                                    self.disabledPage = false
                                }
                            }
                        }
                    }
            
        }.padding(.top)
        
    }
	
    
    
    @ViewBuilder
    private func registerButton()-> some View{
        VStack{
            
            
            AnimatedButton(  state: $buttonState, normal:
                    .init(title: String(localized: "注册KEY"),background: .blue,symbolImage: "person.crop.square.filled.and.at.rectangle"), success:
                    .init(title: String(localized: "注册成功"), background: .green,symbolImage: "checkmark.circle"), fail:
                    .init(title: String(localized: "注册失败"),background: .red,symbolImage: "xmark.circle"), loadings: [
                        .init(title: String(localized: "检查参数..."), background: .cyan),
                        .init(title: String(localized: "注册中..."), background: .cyan)
                    ]) { view in
                        
                        self.disabledPage = true
                        self.buttonState = .loading(0)
                        try? await Task.sleep(for: .seconds(0.5))
                        
                        guard keyHost.count > 3 && keyHost.isValidURL() == .remote else {
                            Toast.error(title: String(localized: "格式错误"))
                            await view.next(.fail)
                            DispatchQueue.main.async {
                                self.disabledPage = false
                            }
                            return
                        }
                        
                        await view.next(.loading(1))
                       
                        
                        let item = PushServerModel(url: keyHost)
                        manager.appendServer(server: item){success,msg in
                            Toast.info(title: msg)
                            Task{
                                if success{
                                    
                                    try? await Task.sleep(for: .seconds(1))
                                    await view.next(.success){
                                        DispatchQueue.main.async{
                                            self.dismiss()
                                            self.disabledPage = false
                                        }
                                    }
                                   
                                    
                                }else {
                                    await view.next(.fail)
                                    DispatchQueue.main.async {
                                        self.disabledPage = false
                                    }
                                }
                            }
                        }
                        
                    }
            
        }.padding(.top)
        
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
	
}



#Preview {
    ChangeKeyCenterView(dismiss: {})
}




