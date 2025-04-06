//
//  SettingsPage.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
//


import SwiftUI
import Defaults


struct SettingsPage: View {

	@EnvironmentObject private var manager:PushbackManager
	@EnvironmentObject private var store:AppState
    
    @StateObject var monitor = MonitorsManager.shared
	
	@Default(.appIcon) var setting_active_app_icon
	@Default(.sound) var sound
	
	@Default(.servers) var servers


	@State private var webShow:Bool = false
	@State private var webUrl:String = BaseConfig.helpWebUrl
	@State private var showLoading:Bool = false
	@State private var showPaywall:Bool = false
	@State private var buildDetail:Bool = false
	@State private var showServerListView:Bool = false
	@State private var resetAppShow:Bool = false


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


		if buildDetail{
			return "\(appVersion)(\(buildVersion))"
		}else{
			return appVersion
		}



	}



	var body: some View {
		NavigationStack{
			List{

				if ISPAD{
					NavigationLink{
                        MessagePage()
							.navigationTitle( "消息")
					}label: {
						Label( "消息", systemImage: "app.badge")

					}

				}
                
               

				Section(header:Text( "基础配置")) {
                    NavigationLink{
                        ServersConfigView()
                            .toolbar(.hidden, for: .tabBar)
                    }label:{
                        
                        Label {
                            Text("令牌与服务器")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "externaldrive.badge.wifi")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(serverTypeColor,Color.primary)
                                .if(serverTypeColor == .red){view in
                                    view
                                        .symbolEffect(.variableColor, delay: 0.5)
                                }
                        }
                    }
                    
                    NavigationLink{
                        AssistantSettingsView(showClose: false)
                            .toolbar(.hidden, for: .tabBar)
                    }label:{
                        
                        Label {
                            Text("智能助手")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "message.badge.waveform")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green,Color.primary)
                                .symbolEffect(.variableColor)
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
							Text(sound)
								.scaleEffect(0.9)
								.foregroundStyle(.gray)
						}
					}
                    
                    
                    Button{
                        manager.sheetPage = .cloudIcon
                    }label: {
                        HStack{
                            Label {
                                Text( "云图标")
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                ZStack{
                                    Image(systemName: "icloud")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.primary)
                                    Image(systemName: "photo")
                                        .scaleEffect(0.4)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.tint)
                                        .offset(y: 2)
                                } .scaleEffect(0.9)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                    }


					NavigationLink{
                        MoreOperationsView()
							.toolbar(.hidden, for: .tabBar)
					}label: {

						HStack{
							Label {
								Text( "更多操作")
							} icon: {
								Image(systemName: "gearshape.arrow.triangle.2.circlepath")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
                                    .symbolEffect(.rotate, delay: 2)
							}
							Spacer()
						}
					}

				}
				Section {


					Button{
                        PushbackManager.openSetting()
					}label: {
						HStack(alignment:.center){

							Label {
								Text( "系统设置")
									.foregroundStyle(.textBlack)
							} icon: {
								Image(systemName: "gear.circle")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
                                    .symbolEffect(.rotate)

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
                    
                    
                    if store.subscriptionInfo.canAccessContent{
                        HStack{
                            Spacer()
                            Label {

                                Text(store.subscriptionInfo.subscriptionState.description)
                                    .foregroundStyle(.textBlack)
                            } icon: {
                                Image(systemName: "bolt.shield")
                                    .scaleEffect(0.9)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.tint, Color.primary)
                            }
                            Spacer()
                        }
                    }else{
                        Button{
                            self.showPaywall.toggle()
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
                                        .symbolEffect(delay: 0)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }

                        }


                    }

                }header:{
                    Text( "设置与帮助" )
                }footer:{
                    HStack(spacing: 7){
                        Spacer(minLength: 10)


                        Text("\(buildVersion)")
                            .onTapGesture {
                                buildDetail.toggle()
                            }
                            .onTapGesture(count: 7) {
                                self.resetAppShow.toggle()
                            }
                        Circle()
                            .frame(width: 3,height: 3)
                        Button{
                            manager.fullPage = .web(BaseConfig.privacyURL)
                        }label: {
                            Text("隐私政策")
                             
                                
                        }
                        Circle()
                            .frame(width: 3,height: 3)
                        Button{
                            manager.fullPage = .web(BaseConfig.userAgreement)
                        }label: {
                            Text("用户协议")
                               
                        }
                        Circle()
                            .frame(width: 3,height: 3)
                        Button{
                            Task{
                                await store.restorePurchases()
                            }
                        }label: {
                            Text("恢复购买")
                              
                        }

                        Spacer(minLength: 10)
                    }
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }

			}
			.navigationTitle("设置")
			.loading(showLoading)
			.tipsToolbar(wifi: monitor.isConnected, notification: monitor.isAuthorized, callback: {
                PushbackManager.openSetting()
			})
			.toolbar {
                
                ToolbarItem {
                    Button {
                        manager.fullPage = .scan
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(delay: 0)
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
		.sheet(isPresented: $showPaywall) {
			// MARK: - 此处mac 报错找不到 AppState 故加上environmentObject
			PaywallView().environmentObject(AppState.shared)
                .customPresentationCornerRadius(20)
		}

		.alert(isPresented: $resetAppShow) {
			Alert(title: Text("危险操作!!! 恢复初始化."),
				  message:  Text("将丢失所有数据"),
				  primaryButton: .destructive(Text("确定"), action: { resetApp() }),
				  secondaryButton: .cancel()
			)}


	}

	

	fileprivate func resetApp(){
		DEFAULTSTORE.removeAll()
        RealmManager.realm { proxy in
            proxy.deleteAll()
        }
		exit(0)
	}

}


#Preview {
	NavigationStack{
        SettingsPage()
			.environmentObject(PushbackManager.shared)
			.environmentObject(AppState.shared)
	}

}
