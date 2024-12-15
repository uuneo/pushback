//
//  SettingsView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//


import SwiftUI
import RealmSwift
import Combine
import Defaults
import RevenueCat
import RevenueCatUI





struct SettingsView: View {
	
	
	@EnvironmentObject private var manager:PushbackManager
	@ObservedResults(Message.self) var messages
	@Default(.appIcon) var setting_active_app_icon
	@Default(.badgeMode) var badgeMode
	@Default(.sound) var sound
	@Default(.deviceToken) var deviceToken
	@Default(.servers) var servers


	@State private var webShow:Bool = false
	@State private var webUrl:String = BaseConfig.helpWebUrl

	@State private var showLoading:Bool = false
	
	@State private var showServerListView:Bool = false


	@State private var showPayWall:Bool = false

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
	
	
	var body: some View {
		NavigationStack{
			List{
				
				if ISPAD{
					NavigationLink{
						MessageHomeView()
							.navigationTitle( "消息")
					}label: {
						Label( "消息", systemImage: "app.badge")
							
					}
					
				}
				
				
				Section(header:Text(  "设备推送令牌")) {
					Button{
						if deviceToken != ""{
							manager.copy(deviceToken)
							
							Toast.shared.present(title: String(localized: "复制成功"), symbol: "checkmark.arrow.trianglehead.counterclockwise")
							
						}else{
							
							Toast.shared.present(title:  String(localized: "请先注册"), symbol: "questionmark.circle.dashed")
						}
					}label: {
						HStack{
							
							Label {
								Text( "令牌")
									.lineLimit(1)
									.foregroundStyle(.textBlack)
							} icon: {
								Image(systemName: "key")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(Color.primary, .tint)
							}
							
							
							Spacer()
							Text(maskString(deviceToken))
								.foregroundStyle(.gray)
							Image(systemName: "doc.on.doc")
								.scaleEffect(0.9)
						}
					}
				}

				
				Section(header: Text(  "App配置")) {
					Button{
						manager.sheetPage = .appIcon
					}label: {
						
						
						HStack(alignment:.center){
							Label {
								Text("程序图标")
									.foregroundStyle(.textBlack)
							} icon: {
								Image(setting_active_app_icon.logo)
									.resizable()
									.scaledToFit()
									.frame(width: 25)
									.clipShape(RoundedRectangle(cornerRadius: 10))
									.scaleEffect(0.9)
							}
							Spacer()
							Image(systemName: "chevron.right")
								.foregroundStyle(.gray)
								
						}
						
					}
					
					
					Picker(selection: $badgeMode) {
						Text( "自动").tag(BadgeAutoMode.auto)
						Text( "自定义").tag(BadgeAutoMode.custom)
					} label: {
						Label {
							Text( "角标模式")
						} icon: {
							Image(systemName: "app.badge")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
						}
					}.onChange(of: badgeMode) { newValue in
						RealmManager.ChangeBadge()
					}

					
					
					NavigationLink{
						SoundView()
							.toolbar(.hidden, for: .tabBar)
					}label: {
						
						HStack{
							Label {
								Text( "铃声列表")
							} icon: {
								Image(systemName: "headphones.circle")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
							}
							Spacer()
							Text(sound.name)
								.scaleEffect(0.9)
								.foregroundStyle(.gray)
						}
					}


					NavigationLink{
						DataStorageView()
					}label: {

						HStack{
							Label {
								Text( "数据与存储")
							} icon: {
								Image(systemName: "externaldrive")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
							}
							Spacer()
						}
					}
					NavigationLink{
						PrivacySecureView()
					}label: {

						HStack{
							Label {
								Text( "隐私与安全")
							} icon: {
								Image(systemName: "lock.square.stack")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
							}
							Spacer()
						}
					}


					
				}
				Section(header:Text( "设置与帮助" )) {

					
					Button{
						manager.openSetting()
					}label: {
						HStack(alignment:.center){
							
							Label {
								Text(  "系统设置")
									.foregroundStyle(.textBlack)
							} icon: {
								Image(systemName: "gear.circle")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
								
							}
							
							Spacer()
							Image(systemName: "chevron.right")
								.foregroundStyle(.gray)
						}
						
					}
					
					Button{
						manager.fullPage = .web(BaseConfig.helpWebUrl)

					}label: {
						HStack(alignment:.center){
							Label {
								Text( "使用帮助")
									.foregroundStyle(.textBlack)
							} icon: {
								Image(systemName: "person.fill.questionmark")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
							}
							
							Spacer()
							Image(systemName: "chevron.right")
								.foregroundStyle(.gray)
						}
						
					}
					
				}
				
				Section {
					
					if let premiumSubscriptionInfo = manager.premiumSubscriptionInfo,
					   premiumSubscriptionInfo.canAccessContent
					{
						HStack{
							Spacer()
							Text(premiumSubscriptionInfo.subscriptionState.description)
							Spacer()
						}
						
					}else{
						Button{
							
						}label:{
							
							HStack(alignment:.center){
								
								
								Label {
									
									Text("开发者支持计划")
										.foregroundStyle(.textBlack)
								} icon: {
									Image(systemName: "creditcard.circle")
										.scaleEffect(0.9)
										.symbolRenderingMode(.palette)
										.foregroundStyle(.tint, Color.primary)
								}
								
								Spacer()
								Image(systemName: "chevron.right")
									.foregroundStyle(.gray)
							}
							
						}
						.showPayWell(false)
					}
				}footer:{
					HStack{
						Spacer()
						Text("版本号: ")
						var buildVersion:String{
							// 版本号
							let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
							// build号
							let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
							
							return "\(appVersion)(\(buildVersion))"
						}
						
						Text(buildVersion)
						Spacer()
					}
				}
				
				
				
				
				
				
			}
			.navigationTitle("设置")
			.loading(showLoading)
			.tipsToolbar(wifi: MonitorsManager.shared.isConnected, notification: MonitorsManager.shared.isAuthorized, callback: {
				manager.openSetting()
			})
			.toolbar {
				
				ToolbarItem {
					
					Button {
						showServerListView.toggle()
					} label: {
						Image(systemName: "externaldrive.badge.wifi")
							.symbolRenderingMode(.palette)
							.foregroundStyle(serverTypeColor,Color.primary)
					}
					
				}
				
				
			}
			.onAppear {
				manager.healths()
			}
			.navigationDestination(isPresented: $showServerListView) {
				ServersConfigView()
					.toolbar(.hidden, for: .tabBar)
			}
			
			
			
		}
		
	}
	
	private func maskString(_ str: String) -> String {
		guard str.count > 6 else {
			return str
		}
		
		let start = str.prefix(3)
		let end = str.suffix(4)
		let masked = String(repeating: "*", count: 5) // 固定为5个星号
		
		return start + masked + end
	}

	
}


#Preview {
	NavigationStack{
		SettingsView()
			.environmentObject(PushbackManager.shared)
	}
	
}
