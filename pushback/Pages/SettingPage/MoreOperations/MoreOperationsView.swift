//
//  File name:     DataStorageView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/11.


import SwiftUI
import RealmSwift
import Defaults
import UniformTypeIdentifiers
import SwiftyJSON
import Photos

struct MoreOperationsView: View {
    @EnvironmentObject private var manager:AppManager
	@Default(.messageExpiration) var messageExpiration
	@Default(.imageSaveDays) var imageSaveDays
	@Default(.autoSaveToAlbum) var autoSaveToAlbum
    
    @Default(.badgeMode) var badgeMode
    @Default(.showMessageAvatar) var showMessageAvatar
    
    @Default(.defaultBrowser) var defaultBrowser

	

	var body: some View {

			List{
                
                Section(header: Text("默认浏览器设置")){
                    HStack{
                        Picker(selection: $defaultBrowser) {
                            ForEach(DefaultBrowserModel.allCases, id: \.self) { item in
                                Text(item.title)
                                    .tag(item)
                            }
                        }label:{
                            Text("默认浏览器")
                        }.pickerStyle(SegmentedPickerStyle())

                    }
                    
                   
                    
                }
                
                Section{
                    ListButton {
                        Label {
                            Text("语音配置")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "waveform.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                
                        }
                    } action:{
                        manager.router.append(.tts)
                        return true
                    }
                   
                    
                    ListButton {
                        Label {
                            Text("小组件")
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "window.shade.closed")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint, Color.primary)
                                
                        }
                    } action:{
                        manager.router.append(.widget(title: nil, data: "app"))
                        return true
                    }
                    
                    ListButton {
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
                    } action:{
                        AppManager.openSetting()
                        return true
                    }
                }
             
                
				Section {
                    
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
                                .symbolEffect(.pulse, delay: 3)
                        }
                    }.onChange(of: badgeMode) { newValue in
                        if Defaults[.badgeMode] == .auto{
                            RealmManager.handler{ proxy in
                                let unRead = proxy.objects(Message.self).filter({ !$0.read }).count
                                UNUserNotificationCenter.current().setBadgeCount( unRead == 0 ? -1 : unRead)
                            }
                        }
                    }
                    
                    
                    Toggle(isOn: $showMessageAvatar) {
                        Label("显示图标", systemImage: showMessageAvatar ? "camera.macro.circle" : "camera.macro.slash.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .symbolEffect(.replace)
                        
                    }


					Picker(selection: $messageExpiration) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "消息存档")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
                                .foregroundStyle((messageExpiration == .no ? .red : (messageExpiration == .forever  ? .green : .yellow)), Color.primary)
                                .symbolEffect(.pulse, delay: 1)

						}
					}
                



				}header:{
                    Text("信息页面")
                        .textCase(.none)
				}footer:{

					Text( "当推送请求URL没有指定 isArchive 参数时，将按照此设置来决定是否保存通知消息")
						.foregroundStyle(.gray)

				}


				Section {
                    
                    Toggle(isOn: $autoSaveToAlbum) {
                        Label("自动保存到相册", systemImage: "a.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .symbolEffect(.rotate, delay: 3)
                            .onChange(of: autoSaveToAlbum) { newValue in
                                if newValue{
                                    PHPhotoLibrary.requestAuthorization{status in
                                        switch status {
                                        case .notDetermined:
                                            Toast.info(title:"用户尚未做出选择")
                                           
                                        case .restricted:
                                            Toast.info(title: "访问受限（可能是家长控制）")
                                   
                                        case .denied:
                                            Toast.info(title: "用户拒绝了访问权限")
                                     
                                        case .authorized:
                                            Toast.success(title: "用户已授权访问照片库")
            
                                        case .limited:
                                            Toast.info(title: "用户授予了有限的访问权限")
                                            
                                        @unknown default:
                                           break
                                      
                                        }
                                    }
                                }
                            }
                        
                    }


					Picker(selection: $imageSaveDays) {
						ForEach(ExpirationTime.allCases, id: \.self){ item in
							Text(item.title)
								.tag(item)
						}
					} label: {
						Label {
							Text( "图片存档")
						} icon: {
							Image(systemName: "externaldrive.badge.timemachine")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
                                .symbolEffect(.pulse, delay: 1)
                                .foregroundStyle((imageSaveDays == .no ? .red : (imageSaveDays == .forever  ? .green : .yellow)), Color.primary)

						}
					}


				}header :{
					Text(  "图片存档")
						.foregroundStyle(.gray)
                        .textCase(.none)

				}footer:{
					Text("图片默认保存时间，本地化图片不受影响")
				}
                
			}
			.navigationTitle("更多操作")
			
		
	}

   
	
}

#Preview {
    MoreOperationsView()
}


