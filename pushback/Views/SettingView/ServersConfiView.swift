//
//  ServersConfiView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//

import SwiftUI
import Defaults

struct ServersConfigView: View {
	@Environment(\.dismiss) var dismiss
	@Default(.servers) var servers
	@EnvironmentObject private var manager:PushbackManager
	
	@State private var showAction:Bool = false
	@State private var isEditing:EditMode = .inactive
	@State private var serverText:String = ""
	@State private var serverName:String = ""
	@State private var pickerSelect:requestHeader = .https
	var showClose:Bool = false
	@State private  var animationError = false
	private let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
	var body: some View {
		NavigationStack{
			VStack{
				
				List{
					
					if isEditing == .active{
						
						VStack(alignment: .leading){
							Text(String(localized: "新增服务器地址"))
								.font(.body.bold())
								.foregroundStyle(.gray)
								.padding(.vertical, 10)
								.transition(.slide)
							
							TextField(String(localized: "输入服务器地址"), text: $serverName)
								.textContentType(.flightNumber)
								.keyboardType(.URL)
								.autocapitalization(.none)
								.disableAutocorrection(true)
								.padding(.leading, 100)
								.overlay{
									HStack{
										Picker(selection: $pickerSelect) {
											Text(requestHeader.http.rawValue).tag(requestHeader.http)
											Text(requestHeader.https.rawValue).tag(requestHeader.https)
										}label:{}.pickerStyle(.automatic)
											.frame(maxWidth: 100)
											.offset(x:-20)
										Spacer()
									}
									
								}
							
							
							HStack{
								Button{
									manager.webUrl = BaseConfig.delpoydoc
									manager.fullPage = .web
								}label: {
									Text(String(localized: "查看服务器部署教程"))
										.font(.caption2)
								}
								
								Spacer()
								
								Button{
									
									_servers.reset()
									
								}label: {
									Text(String(localized: "恢复默认服务器"))
										.font(.caption2)
								}
								
							}.padding(.vertical, 10)
						}
						.transition(.slide)
						
						
						
					}
					
		
					ForEach(servers, id: \.id){ item in
						HStack(alignment: .center){
							VStack{
								if item.status{
									Image(systemName: "antenna.radiowaves.left.and.right")
										.scaleEffect(1.5)
										.symbolRenderingMode(.palette)
										.foregroundStyle( Color.primary, .green)
									
								}else{
									Image(systemName: animationError ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
										.scaleEffect(1.5)
										.symbolRenderingMode(.palette)
										.foregroundStyle(Color.primary, .red)
										
									
								}
								
							}
							.padding(.horizontal,5)
							.onReceive(timer) { _ in
								if !item.status{
									withAnimation {
										self.animationError.toggle()
									}
								}
								
							}
							
							VStack{
								HStack(alignment: .bottom){
									Text(String(localized: "服务器") + ":")
										.font(.system(size: 10))
										.frame(width: 40)
									Text(item.name)
										.font(.headline)
										.lineLimit(1)
										.minimumScaleFactor(0.5)
									Spacer()
								}
								
								HStack(alignment: .bottom){
									Text("KEY:")
										.frame(width:40)
									Text(item.key)
										.lineLimit(1)
										.minimumScaleFactor(0.5)
									Spacer()
								} .font(.system(size: 10))
								
							}
							Spacer()
							Image(systemName: "doc.on.doc")
								.symbolRenderingMode(.palette)
								.foregroundStyle( .tint, Color.primary)
								.onTapGesture{
									Toast.shared.present(title: String(localized: "复制成功"), symbol: .copy)
									manager.copy( item.url + "/" + item.key)
								}
							
						}
						.padding(.vertical,5)
						.swipeActions(edge: .leading, allowsFullSwipe: true) {
							
							Button {
								manager.fullPage = .login
								manager.sheetPage = .none
							} label: {
								Text(String(localized:  "修改key"))
							}.tint(.blue)
						}
						.listRowSeparator(.hidden)
						.swipeActions(edge: .leading) {
							Button{
								
								if let index = servers.firstIndex(where: {$0.id == item.id}){
									servers[index].key = ""
									manager.register(server: servers[index] ){ _, msg in
										Toast.shared.present(title: msg, symbol: "questionmark.bubble")
									}
								}else{
									Toast.shared.present(title: String(localized: "操作成功"), symbol: .success)
								}
								
								
							}label: {
								Text(String(localized: "重置Key"))
							}.tint(.red)
						}
						
					}
					.onDelete(perform: { indexSet in
						if isEditing == .active{
							if servers.count > 1{
								servers.remove(atOffsets: indexSet)
							}else{
								Toast.shared.present(title:String(localized: "必须保留一个服务"), symbol: .info, tint: .red)
							}
						}else{
							Toast.shared.present(title:String(localized: "编辑状态"), symbol: .info)
						}
					})
					.onMove(perform: { indices, newOffset in
						servers.move(fromOffsets: indices, toOffset: newOffset)
					})
					
					
					
					
				}
				.listRowSpacing(20)
				.refreshable {
					// MARK: - 刷新策略
					manager.registers()
				}
				
				
			}
			
			.toolbar{
				
				ToolbarItem {
					Button {
						manager.fullPage = .scan
					} label: {
						Image(systemName: "qrcode.viewfinder")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint, Color.primary)
					}
					
				}
				
				ToolbarItem {
					withAnimation {
						EditButton()
					}
					
				}
				
				
				if showClose {
					
					ToolbarItem{
						Button {
							dismiss()
						} label: {
							Image(systemName: "xmark.seal")
						}
						
					}
				}
			}
			.environment(\.editMode, $isEditing)
			.navigationTitle(String(localized: "服务器列表"))
			
			.onChange(of: isEditing) { value in
				if isEditing == .inactive && serverName.count > 0{
					let serverUrl = "\(pickerSelect.rawValue)\(serverName)"
					if serverUrl.isValidURL() == .remote {
						let item = PushServerModal(url: serverUrl)
						manager.appendServer(server: item){_,msg in
							Toast.shared.present(title: msg, symbol: .info)
							self.serverName = ""
						}
						
					}
					
					
				}
				
			}
			
		}
	}
	
}

#Preview {
	ServersConfigView()
		.environmentObject(PushbackManager.shared)
}



