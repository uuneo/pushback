//
//  AppIconView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import Defaults

struct AppIconView: View {
    @Environment(\.dismiss) var dismiss
	@Default(.appIcon) var setting_active_app_icon
    var body: some View {
		
		ScrollView(.horizontal) {
			HStack{
				ForEach(AppIconEnum.allCases, id: \.self){ item in
					ZStack{
						Image(item.logo)
							.resizable()
							.customDraggable(100)
							.clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
							.frame(width: 150,height: 150)
							.shadow(radius: 3)
							.tag(item)
						Image(systemName: "checkmark.seal.fill")
							.font(.system(.largeTitle))
							.scaleEffect(item == setting_active_app_icon ? 1 : 0.1)
							.opacity(item == setting_active_app_icon ? 1 : 0)
							.foregroundStyle(.green)
						
					}.animation(.spring, value: setting_active_app_icon)
						.padding()
							.listRowBackground(Color.clear)
							.onTapGesture {
								setting_active_app_icon = item
								let manager = UIApplication.shared



								var iconName:String? = manager.alternateIconName ?? AppIconEnum.def.rawValue
								
								if setting_active_app_icon.rawValue == iconName{
									return
								}
								
								if setting_active_app_icon != .def{
									iconName = setting_active_app_icon.rawValue
								}

								if UIApplication.shared.supportsAlternateIcons {
									Task{
										do {
											try await manager.setAlternateIconName(iconName)
											await MainActor.run {
												dismiss()
											}
//											applicationIconImage
										}catch{
	#if DEBUG
											print(error.localizedDescription)
											Toast.shared.present(title: error.localizedDescription, symbol: .error)
	#endif
											
										}

									}
								   
								}else{
									Toast.shared.present(title: String(localized: "暂时不能切换"), symbol: .question, tint: .red, timing: .short)
								}
							}
					
				   
				}
			}
		}
		.scrollIndicators(.hidden)
		.navigationTitle( "程序图标")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar{
			ToolbarItem{
				Button{
					self.dismiss()
				}label:{
					Image(systemName: "xmark.seal")
				}
				
			}
		}
        
    }
}

#Preview {
    AppIconView()
}
