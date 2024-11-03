//
//  CryptoConfigView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import Defaults

struct CryptoConfigView: View {
	@Environment(\.dismiss) var dismiss
	@EnvironmentObject private var manager:PushbackManager
	@Default(.cryptoConfig) var cryptoConfig
	@Default(.servers) var servers
	
	
	@FocusState private var keyFocus
	@FocusState private var ivFocus
	
	var expectKeyLength:Int {
		cryptoConfig.algorithm.rawValue
	}
	
	var labelIcoc:String{
		switch cryptoConfig.algorithm{
		case .AES128:
			"gauge.low"
		case .AES192:
			"gauge.medium"
		case .AES256:
			"gauge.high"
		}
	}
	
	var modeIcon:String{
		switch cryptoConfig.mode{
		case .CBC:
			"circle.grid.cross.left.filled"
		case .ECB:
			"circle.grid.cross.up.filled"
		case .GCM:
			"circle.grid.cross.right.filled"
		}
	}
	
	
	var body: some View {
		List {
			
			
			Section{
				Picker(selection: $cryptoConfig.algorithm, label:
						Label(String(localized: "算法"), systemImage: labelIcoc)
						.symbolRenderingMode(.palette)
						.foregroundStyle( .tint, Color.primary)
						
				
				) {
					ForEach(CryptoAlgorithm.allCases,id: \.self){item in
						Text(item.name).tag(item)
					}
				}
			}
			
			Section {
				Picker(selection: $cryptoConfig.mode, label:
						Label(String(localized:  "模式"), systemImage: modeIcon)
					.symbolRenderingMode(.palette)
					.foregroundStyle( .tint, Color.primary)
					
				) {
					ForEach(CryptoMode.allCases,id: \.self){item in
						Text(item.rawValue).tag(item)
					}
				}
			}
			
			Section {
				
				HStack{
					Label {
						Text("Padding:")
					} icon: {
						Image(systemName: "p.circle")
							.symbolRenderingMode(.palette)
							.foregroundStyle( Color.primary, .tint)
					}
					Spacer()
					Text(cryptoConfig.mode.padding)
						.foregroundStyle(.gray)
				}
				
			}
			
			Section {
				
				HStack{
					Label {
						Text("Key：")
					} icon: {
						Image(systemName: "key")
							.symbolRenderingMode(.palette)
							.foregroundStyle( Color.primary, .tint)
					}
					Spacer()
					
				
					
					TextEditor(text: $cryptoConfig.key)
						.focused($keyFocus)
						.frame(minHeight: 50)
						.overlay{
							if cryptoConfig.key.isEmpty{
								Text(String(format: String(localized: "输入%d位数的key"), expectKeyLength))
									
							}
						}
						.onDisappear{
							let _ = verifyKey()
						}
						.foregroundStyle(.gray)
						.lineLimit(2)
						
				}
				
				
				
			}
			
			
			Section {
				
				
				HStack{
					Label {
						Text("Iv：")
					} icon: {
						Image(systemName: "dice")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint, Color.primary)
							
					}
					Spacer()
					
					TextEditor(text: $cryptoConfig.iv)
						.focused($ivFocus)
						.overlay{
							if cryptoConfig.iv.isEmpty{
								Text(String(localized: "请输入16位Iv"))
									
							}
						}
						.onDisappear{
							let _ = verifyIv()
						}
						.foregroundStyle(.gray)
						.lineLimit(2)
						

						
				}
				
				
			}
			
			
			
			HStack{
				Spacer()
				Button {
					createCopyText()
				} label: {
					Label(String(localized:  "复制发送脚本"), systemImage: "doc.on.doc")
						.symbolRenderingMode(.palette)
						.foregroundStyle(.white, Color.primary)
						.padding(.horizontal)
					
				}.buttonStyle(BorderedProminentButtonStyle())
				
				
				Spacer()
			} .listRowBackground(Color.clear)
			
			
			
			
			
			
		}.navigationTitle(String(localized:  "算法配置"))
			.toolbar{
				
				ToolbarItemGroup(placement: .keyboard) {
					Button(String(localized: "清除")) {
						if keyFocus {
							cryptoConfig.key = ""
						}else if ivFocus{
							cryptoConfig.iv = ""
						}
					}
					Spacer()
					Button(String(localized: "完成")) {
						if keyFocus {
							keyFocus.toggle()
						}else if ivFocus{
							ivFocus.toggle()
						}
					}
				}
				
				ToolbarItem {
					Button {
						if verifyKey() && verifyIv(){
							
							Toast.shared.present(title: String(localized:  "验证成功"), symbol: .success)
							
							
						}
					} label: {
						Text(String(localized:  "验证"))
					}
					
				}
			}
		
	}
	func verifyKey()-> Bool{
		if cryptoConfig.key.count != expectKeyLength{
			cryptoConfig.key = ""
		
			Toast.shared.present(title: String(localized:  "Key参数长度不正确"), symbol: .info)
			return false
		}
		return true
	}
	
	func verifyIv() -> Bool{
		if cryptoConfig.iv.count != 16 {
			cryptoConfig.iv = ""
			Toast.shared.present(title: String(localized:  "Iv参数长度不正确"), symbol: .info)
			return false
		}
		return true
	}
	
	
	func createCopyText(){
		
		
		if !verifyIv() {
			cryptoConfig.iv = CryptoModal.generateRandomString(by32: false)
		}
		
		if !verifyKey(){
			cryptoConfig.key = CryptoModal.generateRandomString(by32: expectKeyLength == 32)
		}
		
		
		
		let text = CreateCryptoExample.shared.cryptoExampleHandler()
		manager.copy(text)
		Toast.shared.present(title: String(localized:  "复制成功"), symbol: .copy)
		
	}
	
	
}

#Preview {
	CryptoConfigView()
		.environmentObject(PushbackManager.shared)
}
