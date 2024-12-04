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
	@State private var serverText:String = ""
	@State private var serverName:String = ""
	@State private var pickerSelect:requestHeader = .https
	@State private var showAddView:Bool = false
	@State private var cloudDatas:[PushServerModal] = []
	@FocusState private var serverNameFocus
	
	
	var showClose:Bool = false
	var filteredCloudDatas:[PushServerModal]{
		self.cloudDatas.filter { item in
			// 筛选不在本地服务器列表中的云服务器
			!servers.contains(where: { $0.url == item.url && $0.key == item.key })
		}
	}
	var body: some View {
		NavigationStack{
			List{
					
				ForEach(servers, id: \.id){ item in
					
					ServerCardView( item: item)
					.padding(.vertical,5)
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						
						Button {
							manager.fullPage = .login
							manager.sheetPage = .none
						} label: {
							Text(  "修改key")
						}.tint(.blue)
					}
					.listRowSeparator(.hidden)
					.swipeActions(edge: .leading) {
						Button{
							
							if let index = servers.firstIndex(where: {$0.id == item.id}){
								
								servers[index].key = ""
								servers[index].id = UUID().uuidString
								manager.register(server: servers[index] ){ _, msg in
									Toast.shared.present(title: msg, symbol: "questionmark.bubble")
								}
							}else{
								Toast.shared.present(title: String(localized: "操作成功"), symbol: .success)
							}
							
							
						}label: {
							Text( "重置Key")
						}.tint(.red)
					}
					.swipeActions(edge: .trailing,allowsFullSwipe: true) {
						Button{
							if servers.count > 1{
								if let index = servers.firstIndex(where: {$0.id == item.id}){
									servers.remove(at: index)
								}
							}else{
								Toast.shared.present(title:String(localized: "必须保留一个服务"), symbol: .info, tint: .red)
							}
						}label:{
							Text("删除")
								
						}.tint(.red)
						
					}
					
				}
				.onMove(perform: { indices, newOffset in
					servers.move(fromOffsets: indices, toOffset: newOffset)
				})
				
				
				
				
			}
			.padding(.vertical, 30)
			.listRowSpacing(20)
			.refreshable {
				// MARK: - 刷新策略
				await manager.registers(){ result in
					Toast.shared.present(title: String(localized: "操作成功"), symbol: .info)
					
				}
			}
			.toolbar{
				
				ToolbarItem {
					withAnimation {
						Button{
							showAddView.toggle()
						}label:{
							Image(systemName: "externaldrive.badge.plus")
								.symbolRenderingMode(.palette)
								.foregroundStyle( Color.accentColor,Color.primary)
						}
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
			.navigationTitle( "服务器列表")
			.sheet(isPresented: $showAddView) {
				addServerView()
			}
			
		}
	}
	
	
	@ViewBuilder
	func addServerView()-> some View{
		NavigationStack{
			List{
				VStack(alignment: .leading){
					
					HStack{
						Spacer()
						Text( "查看服务器部署教程")
							.font(.caption2)
							.foregroundStyle(Color.accentColor)
							.onTapGesture {
								manager.webUrl = BaseConfig.delpoydoc
								manager.fullPage = .web
							}
						
						
						
					}.padding(.top, 20)
					
					Spacer()
					TextField("输入服务器地址", text: $serverName)
						.textContentType(.flightNumber)
						.keyboardType(.URL)
						.autocapitalization(.none)
						.disableAutocorrection(true)
						.padding(.leading, 100)
						.focused($serverNameFocus)
						.overlay{
							HStack{
								Picker(selection: $pickerSelect) {
									Text(requestHeader.http.rawValue).tag(requestHeader.http)
									Text(requestHeader.https.rawValue).tag(requestHeader.https)
								}label:{}
									.pickerStyle(MenuPickerStyle())
									.frame(maxWidth: 100)
									.offset(x:-20)
						
								Spacer()
							}
							
						}
						.padding()
						.background(.background)
						

					
				
						
					
					Spacer()
					
					
				
					
					
					
				}
				.listRowBackground(Color.clear)
				.listRowInsets(.init())
				
				
				
				
				
				
					
					Section{
						
						
						ForEach(filteredCloudDatas, id: \.id){ item in
						
								ServerCardView(item: item,isCloud: true)
								.padding(.vertical,5)
								.swipeActions(edge: .leading, allowsFullSwipe: true) {
									Button{
										Defaults[.servers].insert(item, at: 0)
										self.showAddView.toggle()
									}label:{
										Text("恢复")
									}.tint(Color.green)
								}
								.swipeActions(edge: .trailing, allowsFullSwipe: true) {
									Button{
										PushServerCloudKit.shared.deleteCloudServer(item.id) { err in
											if let err{
												debugPrint(err.localizedDescription)
											}else{
												updateCloudServers()
											}
											
										}
									}label:{
										Text("删除")
									}.tint(Color.red)
								}
							
							
						}
					}header: {
						HStack{
							
							Text("历史服务器和key")
								.font(.headline)
								.fontWeight(.medium)
								
							Spacer()
							Text("\(self.cloudDatas.count)")
						}
						.padding(.bottom)
					}
					
				
				
				
			}
			.listRowSpacing(20)
			.onAppear{ updateCloudServers() }
			.interactiveDismissDisabled()
			.navigationTitle("新增服务器")
			.toolbar {
				
				ToolbarItemGroup(placement: .keyboard) {
					Button( "清除") {
						serverName = ""
					}
					Spacer()
					Button("完成") {
						PushbackManager.shared.hideKeyboard()
					}
				}
				
				
				ToolbarItem(placement: .topBarLeading) {
					Button(action: {
						self.showAddView.toggle()
					}, label: {
						Image(systemName: "arrow.left")
							.font(.title2)
							.foregroundStyle(.gray)
					})
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button{
						let serverUrl = "\(pickerSelect.rawValue)\(serverName)"
						
						if serverName.count > 3 && serverUrl.isValidURL() == .remote{
							
							let item = PushServerModal(url: serverUrl)
							manager.appendServer(server: item){_,msg in
								Toast.shared.present(title: msg, symbol: .info)
								self.serverName = ""
							}
							
						}else {
							Toast.shared.present(title: String(localized: "格式错误"), symbol: .error)
						}
					} label:{
						Text( "添加")
					}
					
				}
				
				
				ToolbarItem(placement: .topBarTrailing) {
					
					
					
					
					Button {
						manager.fullPage = .scan
					} label: {
						Image(systemName: "qrcode.viewfinder")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint, Color.primary)
					}
				}
			}
			
		}
		.presentationDetents([.height(300),.medium, .large])
	}
	
	
	func updateCloudServers(){
		PushServerCloudKit.shared.fetchPushServerModals { response in
			switch response {
			case .success(let results):
				withAnimation(.easeInOut) {
					self.cloudDatas = results
				}
			case .failure(let failure):
				debugPrint(failure.localizedDescription)
			}
		}
	}
	
	
}

#Preview {
	ServersConfigView()
		.environmentObject(PushbackManager.shared)
}



