//
//  SettingsPage.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//


import SwiftUI
import Defaults


struct SettingsPage: View {

	@EnvironmentObject private var manager:AppManager
    
	
	@Default(.appIcon) var setting_active_app_icon
	
    @Default(.sound) var sound
	@Default(.servers) var servers
    @Default(.assistantAccouns) var assistantAccouns
    
    
	@State private var webShow:Bool = false
	@State private var showLoading:Bool = false
	@State private var showPaywall:Bool = false
	@State private var buildDetail:Bool = false
    
	var serverTypeColor:Color{

		let right =  servers.filter(\.status == true).count
		let left = servers.filter(\.status == false).count

		if right > 0 && left == 0 {
			return .green
		}else if left > 0 && right == 0{
			return .red
		}else {
			return .orange
		}
	}
    
	// 定义一个 NumberFormatter
	private var numberFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 2
		return formatter
	}


	var buildVersion:String{
		// 版本号
		let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		// build号
		let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        return  buildDetail ? "\(appVersion)(\(buildVersion))" : appVersion
	}



	var body: some View {
        List{
            
            Section{
                HStack{
                    Spacer()
                    Image(setting_active_app_icon.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .VButton (onRelease:{ _ in
                            manager.sheetPage = .appIcon
                            return true
                        })
                        .padding(.top, 50)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            
            
            if ISPAD{
                ListButton {
                    Label( "消息", systemImage: "ellipsis.message")
                } action: {
                    manager.router = []
                    return true
                }
            }
            
           
            
            Section(header: Text("App配置") .textCase(.none)) {
                
                ListButton {
                    Label {
                        Text("服务器")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "externaldrive.badge.wifi")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(serverTypeColor, Color.primary)
                            .if(serverTypeColor == .red){view in
                                view
                                    .symbolEffect(.variableColor, delay: 0.5)
                            }
                    }
                } action: {
                    manager.router = [.server]
                    return true
                    
                }
                
                ListButton {
                    Label {
                        Text( "云图标")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        ZStack{
                            Image(systemName: "icloud")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(Color.primary)
                            Image(systemName: "photo")
                                .scaleEffect(0.4)
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent)
                                .offset(y: 2)
                        }
                    }
                } action: {
                    manager.sheetPage = .cloudIcon
                    return true
                }
                
                ListButton {
                    Label {
                        Text( "声音与反馈")
                    } icon: {
                        Image(systemName: "sensor.tag.radiowaves.forward")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                            .symbolEffect(.bounce,delay: 3)
                    }
                } trailing: {
                    Text(sound)
                        .foregroundStyle(.gray)
                } action: {
                    manager.router.append(.sound)
                    return true
                    
                }
                
                ListButton {
                    Label {
                        Text( "算法配置")
                    } icon: {
                        Image(systemName: "key.viewfinder")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.green, Color.primary)
                            .symbolEffect(.pulse, delay: 5)
                            .scaleEffect(0.9)
                    }
                } action: {
                    manager.router.append(.crypto)
                    return true
                }
                
                
                if #available(iOS 18.0, *) {
                    
                    ListButton  {
                        Label {
                            Text( "更多操作")
                        } icon: {
                            Image(systemName: "dial.high")
                            
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, Color.primary)
                                .symbolEffect(.rotate, delay: 2)
                        }
                    } action: {
                        manager.router = [.more]
                        return true
                        
                    }
                }
                
            }
            

            Section {
                
                
                
                
                ListButton {
                    Label {
                        Text( "使用帮助")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "person.fill.questionmark")
                        
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                    }
                } action: {
                    manager.fullPage = .web(BaseConfig.docServer + String(localized: "/#/tutorial"))
                    return true
                }
                
                ListButton {
                    Label {
                        Text( "系统设置")
                            .foregroundStyle(.textBlack)
                    } icon: {
                        Image(systemName: "gear.circle")
                        
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, Color.primary)
                            .symbolEffect(.rotate)
                    }
                } action:{
                    AppManager.openSetting()
                    return true
                }
                
                if #available(iOS 18.0, *) {
                    ListButton {
                        Label {
                            
                            Text("开发者支持计划")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "creditcard.circle")
                            
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, Color.primary)
                                .symbolEffect(delay: 0)
                        }
                    } action: {
                        manager.sheetPage = .paywall
                        return true
                    }
                }else{
                    
                    ListButton  {
                        Label {
                            Text( "更多操作")
                        } icon: {
                            Image(systemName: "dial.high")
                                .symbolRenderingMode(.palette)
                                .customForegroundStyle(.accent, Color.primary)
                                .symbolEffect(.rotate, delay: 2)
                        }
                    } action: {
                        manager.router = [.more]
                        return true
                        
                    }
                }
                
            }header:{
                Text( "其他" )
                    .textCase(.none)
            }footer:{
                HStack(spacing: 7){
                    Spacer(minLength: 10)
                    
                    
                    Text(verbatim: "\(buildVersion)")
                        .onTapGesture {
                            buildDetail.toggle()
                            Haptic.impact()
                        }
                    Circle()
                        .frame(width: 3,height: 3)
                    Button{
                        manager.fullPage = .web(BaseConfig.privacyURL)
                        Haptic.impact()
                    }label: {
                        Text("隐私政策")
                        
                        
                    }
                    Circle()
                        .frame(width: 3,height: 3)
                    Button{
                        manager.fullPage = .web(BaseConfig.userAgreement)
                        Haptic.impact()
                    }label: {
                        Text("用户协议")
                        
                    }
                    
                    Spacer(minLength: 10)
                }
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
            
            
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.fullPage = .scan
                    Haptic.impact()
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .symbolRenderingMode(.palette)
                        .customForegroundStyle(.accent, Color.primary)
                        .symbolEffect(delay: 5)
                        .padding(.trailing, 10)
                }
            }
        }
        .ignoresSafeArea( edges: [.top])
        .toolbarBackground(.hidden, for: .navigationBar)
	}

   

}




#Preview {
	NavigationStack{
        SettingsPage()
			.environmentObject(AppManager.shared)
	}

}
