//
//  AppIconView.swift
//  Meow
//
//  Created by uuneo 2024/8/10.
//

import SwiftUI
import Defaults



struct AppIconView: View {
    @Environment(\.dismiss) var dismiss
	@Default(.appIcon) var setting_active_app_icon
    @State private var PremiumUser:Bool = false
    @EnvironmentObject private var manager:AppManager
    var body: some View {
        
        ScrollView(.horizontal) {
            HStack{
                ForEach(AppIconEnum.allCases, id: \.self){ item in
                    if item == AppIconEnum.allCases.first && manager.PremiumUser {
                        iconItem(item: item)
                    }
                    
                    
                    if item != AppIconEnum.allCases.first {
                        iconItem(item: item)
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
    
    @ViewBuilder
    func iconItem(item:AppIconEnum )->some View{
        ZStack{
            Image(item.logo)
                .resizable()
                .customDraggable(100)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .frame(width: 150,height: 150)
                .shadow(radius: 3)
                .tag(item)
                .overlay(  // 再添加圆角边框
                    ColoredBorder(cornerRadius: 20,padding: 0)
                        .scaleEffect(item == setting_active_app_icon ? 1 : 0.1)
                        .opacity(item == setting_active_app_icon ? 1 : 0)
                )
            
        }
        .animation(.interactiveSpring, value: setting_active_app_icon)
        .padding()
        .listRowBackground(Color.clear)
        .onTapGesture {
            setSystemIcon(item)
        }
    }

	func setSystemIcon(_ icon: AppIconEnum){
		let setting_active_app_icon_backup = setting_active_app_icon

		setting_active_app_icon = icon
        
        let application = UIApplication.shared
        

       
		if application.supportsAlternateIcons {
            application.setAlternateIconName(setting_active_app_icon.name) { err in
				if let err{
					Log.debug(err)
					setting_active_app_icon = setting_active_app_icon_backup
				}
			}

			Toast.success(title: "切换成功", timing: .long)
			dismiss()
		}else{
			Toast.question(title: "暂时不能切换", timing: .short)
		}

	}
}

#Preview {
    AppIconView()
}
