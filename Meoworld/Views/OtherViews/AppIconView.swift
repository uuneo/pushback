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
								setSystemIcon(item)
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

	func setSystemIcon(_ icon: AppIconEnum){
		let setting_active_app_icon_backup = setting_active_app_icon

		setting_active_app_icon = icon

		if UIApplication.shared.supportsAlternateIcons {
			UIApplication.shared.setAlternateIconName(setting_active_app_icon.name) { err in
				if let err{
					debugPrint(err)
					setting_active_app_icon = setting_active_app_icon_backup
				}
			}

			Toast.shared.present(title: String(localized: "切换成功"), symbol: .success, tint: .green, timing: .long)
			dismiss()
		}else{
			Toast.shared.present(title: String(localized: "暂时不能切换"), symbol: .question, tint: .red, timing: .short)
		}
	}
}

#Preview {
    AppIconView()
}
