//
//  ServersConfiView.swift
//  pushback
//
//  Created by uuneo 2024/10/8.
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
	@State private var cloudDatas:[PushServerModel] = []
	@FocusState private var serverNameFocus


	var showClose:Bool = false
	var filteredCloudDatas:[PushServerModel]{
		self.cloudDatas.filter { item in
			// 筛选不在本地服务器列表中的云服务器
			!servers.contains(where: { $0.url == item.url && $0.key == item.key })
		}
	}
    
    @Default(.deviceToken) var deviceToken
    
	var body: some View {
		NavigationStack{
			List{
                
                Section(header:Text( "设备推送令牌")) {
                    Button{
                        if deviceToken != ""{
                            Clipboard.shared.setString(deviceToken)
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


				Section{
					ForEach(servers, id: \.id){ item in


                        Menu{
                            
                            Section{
                                
                                Button{
                                    Clipboard.shared.setString(item.url)
                                    Toast.shared.present(title: String(localized: "复制成功"), symbol: .copy)
                                }label:{
                                    Label("复制URL", systemImage: "doc.on.doc")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.textBlack)
                                }
                                
                                Button{
                                    Clipboard.shared.setString( item.key)
                                    Toast.shared.present(title: String(localized: "复制成功"), symbol: .copy)
                                }label:{
                                    Label("复制KEY", systemImage: "doc.on.doc")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.textBlack)
                                }
                                Button{
                                    Clipboard.shared.setString(item.url + "/" + item.key)
                                    Toast.shared.present(title: String(localized: "复制成功"), symbol: .copy)
                                }label:{
                                    Label("复制URL和KEY", systemImage: "doc.on.doc")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.textBlack)
                                }
                                
                                Button{
                                    manager.fullPage = .customKey
                                    manager.sheetPage = .none
                                }label:{
                                    Label("修改KEY", systemImage: "rectangle.and.pencil.and.ellipsis")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.textBlack)
                                }
                            }
                            
                            Section{
                                
                               
                                
                                
                                Button(role: .destructive){
                                    if let index = servers.firstIndex(where: {$0.id == item.id}){
                                        
                                        servers[index].key = ""
                                        servers[index].id = UUID().uuidString
                                        manager.register(server: servers[index] ){ _, msg in
                                            Toast.shared.present(title: msg, symbol: "questionmark.bubble")
                                        }
                                    }else{
                                        Toast.shared.present(title: String(localized: "操作成功"), symbol: .success)
                                    }
                                    
                                }label:{
                                    Label("重置KEY", systemImage: "eraser.line.dashed")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.green, Color.textBlack)
                                }
                                
                                
                               
                            }
                            
                            Section{
                                Button(role: .destructive){
                                    if servers.count > 1{
                                        if let index = servers.firstIndex(where: {$0.id == item.id}){
                                            servers.remove(at: index)
                                        }
                                    }else{
                                        Toast.shared.present(title:String(localized: "必须保留一个服务"), symbol: .info, tint: .red)
                                    }
                                }label:{
                                    Label("删除", systemImage: "trash")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.red, Color.textBlack)
                                    
                                }
                            }
                           
                        }label:{
                            ServerCardView( item: item)
                                .padding(.vertical,5)
                                .listRowSeparator(.hidden)
                            
                        }



					}
					.onMove(perform: { indices, newOffset in
						servers.move(fromOffsets: indices, toOffset: newOffset)
					})
				}header:{
					Text("使用中的服务器")
				}


				if filteredCloudDatas.count > 0{
					Section{

                        
                        ForEach(filteredCloudDatas, id: \.id){ item in
                            
                            
                            Menu{
                                
                                Section{
                                    Button{
                                        Defaults[.servers].insert(item, at: 0)
                                    }label:{
                                        Label("恢复", systemImage: "checkmark.shield")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.green, Color.accentColor)
                                    }
                                }
                                
                                Section{
                                    Button(role: .destructive){
                                        PushServerCloudKit.shared.deleteCloudServer(item.id) { err in
                                            if let err{
                                                Log.debug(err.localizedDescription)
                                            }else{
                                                updateCloudServers()
                                            }
                                            
                                        }
                                    }label:{
                                        Label("删除", systemImage: "trash")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.red, Color.accentColor)
                                    }
                                }
                                
                            }label:{
                                ServerCardView(item: item,isCloud: true)
                                    .padding(.vertical,5)
                            }
                            
                    
                            
                        }
					}header: {
						HStack{

							Text("历史服务器")
							Spacer()
							Text("\(self.cloudDatas.count)")
						}
					}
					.transaction { view in
						view.animation = .easeInOut
					}
				}



			}
			.animation(.easeInOut, value: servers)
			.listRowSpacing(20)
			.refreshable {
				// MARK: - 刷新策略
				await manager.registers(){ result in
					Toast.shared.present(title: String(localized: "操作成功"), symbol: .info)

				}

				updateCloudServers()
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
			.navigationTitle( "令牌与服务器")
            .navigationBarTitleDisplayMode(.inline)
			.sheet(isPresented: $showAddView) {
				addServerView()
                    .customPresentationCornerRadius(20)
			}
			.onAppear{ updateCloudServers() }

		}
	}


	@ViewBuilder
	func addServerView()-> some View{
		NavigationStack{
			VStack(alignment: .leading){

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
					.clipShape(RoundedRectangle(cornerRadius: 10))
					.shadow(radius: 10)

				HStack{
					Spacer()
					Text( "查看服务器部署教程")
						.font(.caption2)
						.foregroundStyle(Color.accentColor)
						.onTapGesture {
							manager.fullPage = .web(BaseConfig.delpoydoc)
						}



				}.padding(.top, 20)




				Spacer()


			}
			.padding(.horizontal)
			.interactiveDismissDisabled()
			.navigationTitle("新增服务器")
			.navigationBarTitleDisplayMode(.inline)
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

							let item = PushServerModel(url: serverUrl)
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



			}

		}
		.presentationDetents([.height(300)])
	}


	func updateCloudServers(){
		PushServerCloudKit.shared.fetchPushServerModels { response in
			switch response {
				case .success(let results):
					withAnimation(.easeInOut) {
						self.cloudDatas = results
					}
				case .failure(let failure):
					Log.debug(failure.localizedDescription)
			}
		}
	}
    
    
    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 6 else { return str }
        return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(4)
    }


}

#Preview {
	ServersConfigView()
		.environmentObject(PushbackManager.shared)
}



