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
    let columns: [GridItem] = Array(repeating: .init(), count: 3)
    var body: some View {
        List{
            LazyVGrid(columns: columns){
				ForEach(AppIconEnum.allCases, id: \.self){ item in
                    ZStack{
                        Image(item.logo)
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                            .frame(width: 60,height:60)
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
                                }else{
                                    iconName = nil
                                }
                                if UIApplication.shared.supportsAlternateIcons {
                                    Task{
                                        do {
                                            try await manager.setAlternateIconName(iconName)
                                        }catch{
#if DEBUG
											print(error.localizedDescription)
#endif
                                            
                                        }
										await MainActor.run {
                                            dismiss()
                                        }
                                    }
                                   
                                }else{
									Toast.shared.present(title: String(localized: "暂时不能切换"), symbol: .question, tint: .red, timing: .short)
                                }
                            }
                    
                   
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Color.clear)
        }
        .listStyle(GroupedListStyle())
        
        .navigationTitle(String(localized:  "程序图标"))
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
