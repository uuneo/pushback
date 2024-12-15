//
//  CryptoConfigView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import Defaults

struct CryptoConfigView: View {
	@Default(.cryptoConfig) var cryptoConfig
	@Default(.servers) var servers
	
	
	@FocusState private var keyFocus
	@FocusState private var ivFocus
	
	var expectKeyLength:Int {
		cryptoConfig.algorithm.rawValue
	}
	
	var labelIcoc:String{
		switch cryptoConfig.algorithm{
		case .AES128: "gauge.low"
		case .AES192: "gauge.medium"
		case .AES256: "gauge.high"
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
		NavigationStack{
			List {


				Section{
					Picker(selection: $cryptoConfig.algorithm, label:
							Label( "算法", systemImage: labelIcoc)
						.symbolRenderingMode(.palette)
						.foregroundStyle( .tint, Color.primary)


					) {
						ForEach(CryptoAlgorithm.allCases,id: \.self){item in
							Text(item.name).tag(item)
						}
					}
				}header:{
					Text("选择后配置自动保存")
				}
				.onChange(of: cryptoConfig.algorithm) {  _ in
					verifyCopyText()
				}





				Section {
					Picker(selection: $cryptoConfig.mode, label:
							Label("模式", systemImage: modeIcon)
						.symbolRenderingMode(.palette)
						.foregroundStyle( .tint, Color.primary)

					) {
						ForEach(CryptoMode.allCases,id: \.self){item in
							Text(item.rawValue).tag(item)
						}
					}
				}
				.onChange(of: cryptoConfig.mode) {  _ in
					verifyCopyText()
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
									Text( "请输入16位Iv")

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
						verifyCopyText(false)
					} label: {
						Label("复制Python脚本", systemImage: "doc.on.doc")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.white, Color.primary)
							.padding(.horizontal)

					}.buttonStyle(BorderedProminentButtonStyle())
					Spacer()
				} .listRowBackground(Color.clear)
			}
			.navigationTitle( "算法配置")
			.toolbar{

				ToolbarItemGroup(placement: .keyboard) {
					Button("清除") {
						if keyFocus {
							cryptoConfig.key = ""
						}else if ivFocus{
							cryptoConfig.iv = ""
						}
					}
					Spacer()
					Button( "完成") {
						PushbackManager.shared.hideKeyboard()
					}
				}

				ToolbarItem {

					Button {
						cryptoConfig.iv = CryptoModel.generateRandomString()
						cryptoConfig.key = CryptoModel.generateRandomString(cryptoConfig.algorithm.rawValue)
					} label: {
						Label("随机生成密钥", systemImage: "dice")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.green, Color.primary)
							.padding(.horizontal)

					}


				}
			}
		}

		
			
		
	}
	func verifyKey(_ showMsg:Bool = true)-> Bool{
		if cryptoConfig.key.count != expectKeyLength{
			cryptoConfig.key = ""
			if showMsg{
				Toast.shared.present(title: String(localized:  "自动更正Key参数"), symbol: .info)
			}
			return false
		}
		return true
	}
	
	func verifyIv(_ showMsg:Bool = true) -> Bool{
		if cryptoConfig.iv.count != 16 {
			cryptoConfig.iv = ""
			if showMsg{
				Toast.shared.present(title: String(localized:  "自动更正Iv参数"), symbol: .info)
			}
			return false
		}
		return true
	}
	
	
	func verifyCopyText(_ showMsg:Bool = true){
		
		
		if !verifyIv(showMsg) {
			cryptoConfig.iv = CryptoModel.generateRandomString()
		}
		
		if !verifyKey(showMsg){
			cryptoConfig.key = CryptoModel.generateRandomString(cryptoConfig.algorithm.rawValue)
		}
		
		
		if !showMsg{
			PushbackManager.shared.copy(cryptoExampleHandler())
			Toast.shared.present(title: String(localized:  "复制成功"), symbol: .copy)
		}
		
	}
	
	
}

#Preview {
	CryptoConfigView()
		.environmentObject(PushbackManager.shared)
}

