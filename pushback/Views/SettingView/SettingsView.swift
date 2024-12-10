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
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays

	@State private var webShow:Bool = false
	@State private var webUrl:String = BaseConfig.helpWebUrl

	@State private var showLoading:Bool = false
	
	@State private var showServerListView:Bool = false

	@State private var showImport:Bool = false
	
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
			
				
				Section {
					
					HStack{
						ShareLink(item: MessageExportJson(data: Array(messages)), preview:
									SharePreview(Text(String(format: String(localized: "导出%d条通知消息"), messages.count)), image: Image("json_png"), icon: "trash")) {
							Label("导出", systemImage: "arrow.up.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
						}
						
						
						Spacer()
						Text(String(format: String(localized: "%d条消息"), messages.count) )
							.foregroundStyle(Color.green)
					}
					
					Button{
						self.showImport.toggle()
					}label: {
						HStack{
							
							Label( "导入", systemImage: "arrow.down.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
							
							Spacer()
							
						}
					}
					
					
					.fileImporter(isPresented: $showImport, allowedContentTypes: [.trnExportType], allowsMultipleSelection: false, onCompletion: { result in
						switch result {
						case .success(let files):
							Toast.shared.present(title: RealmManager.shared.importMessage(files), symbol: .info)
						case .failure(let err):
							Toast.shared.present(title: err.localizedDescription, symbol: .error)
						}
					})
					
					
					
				} header: {
					Text( "导出消息列表")
				} footer:{
					Text("只能导入.exv结尾的JSON数据")
				}
						 
						 
						 
				
				
				
				
				Section(footer:Text(  "苹果设备推送Token,不要外泄")) {
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
				
				Section {
					
					
					Picker(selection: $messageExpiration) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "默认保存时间")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle((messageExpiration.days == 0 ? .red : (messageExpiration.days == -1 ? .green : .yellow)), Color.primary)
							
							
							
						}
					}
					
					
				}header:{
					Text( "消息存档")
				}footer:{
					
					Text( "当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
						.foregroundStyle(.gray)
					
				}
				
				
				
				
				Section {
					
					NavigationLink {
						ImageCacheView()
							.toolbar(.hidden, for: .tabBar)
							.navigationTitle("图片缓存")
						
					} label: {
						Label("图片缓存", systemImage: "photo.on.rectangle")
							.symbolRenderingMode(.palette)
							.foregroundStyle( .tint, Color.primary)
					}
					
					
					Picker(selection: $imageSaveDays) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "默认保存时间")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle((imageSaveDays.days == 0 ? .red : (imageSaveDays.days == -1 ? .green : .yellow)), Color.primary)
							
						}
					}
					
					
				}header :{
					Text(  "图片存档")
						.foregroundStyle(.gray)
					
				}footer:{
					Text("图片默认保存时间，本地化图片不受影响")
				}
				
				
				
				
				
				Section(header: Text(  "配置")) {
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

					NavigationLink(destination:
									CryptoConfigView()
						.toolbar(.hidden, for: .tabBar)
					) {
						
						
						Label {
							Text( "算法配置")
						} icon: {
							Image(systemName: "bolt.shield")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
						}
					}
					
					NavigationLink{
						RingtongView()
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
					
					
				}
				
				
				Section(header:Text( "系统" )) {
					
					
					Button{
						manager.openSetting()
					}label: {
						HStack(alignment:.center){
							
							Label {
								Text(  "打开设置")
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
						manager.webUrl = BaseConfig.helpWebUrl
						manager.fullPage = .web
						
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
					}.padding(.vertical)
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
