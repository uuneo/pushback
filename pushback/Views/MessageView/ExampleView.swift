//
//  ExampleView.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import SwiftUI
import Defaults

struct ExampleView: View {
    @State private var username:String = ""
    @State private var title:String = ""
    @State private var pickerSeletion:Int = 0
    @State private var showAlart = false
	@Default(.servers) var servers
	
    var body: some View {
        NavigationStack{

            List{
                
                HStack{
                    Spacer()
                    Picker(selection: $pickerSeletion, label: Text(String(localized:  "切换服务器"))) {
                        ForEach(servers.indices, id: \.self){index in
                            let server = servers[index]
                            Text(server.name).tag(server.id)
                        }
                    }.pickerStyle(MenuPickerStyle())
                       
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                customHelpItemView()
               
                
            }.listStyle(GroupedListStyle())
            
                .toolbar{
                    ToolbarItem {
                        
                        NavigationLink {
                            RingtongView()
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
							Image(systemName: "headphones.circle")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
                           
                        }
                    }
                
                    
                }
                .navigationTitle(String(localized: "使用示例"))
              
        }
    }
	
	
	@ViewBuilder
	func customHelpItemView() -> some View{
	   
		ForEach(PushExample.datas,id: \.id){ item in
			let server =  servers[pickerSeletion]
			let resultUrl = server.url + "/" + server.key + "/" + item.params
			Section{
				HStack{
					Text(item.title)
						.font(.headline)
						.fontWeight(.bold)
					Spacer()
					Image(systemName: "doc.on.doc")
						
						.symbolRenderingMode(.palette)
						.foregroundStyle(.tint, Color.primary)
						.padding(.horizontal)
						.onTapGesture {
							UIPasteboard.general.string = resultUrl
			
							Toast.shared.present(title: String(localized:  "复制成功"), symbol: "document.on.document")
						}
					Image(systemName: "safari")
						.scaleEffect(1.3)
						.symbolRenderingMode(.palette)
						.foregroundStyle(.tint, Color.primary)
						.onTapGesture {
							
							let ok =  self.health(item: servers[pickerSeletion])
							if ok{
								if let url = URL(string: resultUrl){
									UIApplication.shared.open(url)
								}
							}else{
								Toast.shared.present(title: String(localized:  "复制成功"), symbol: "document.on.document")
								
							}
							
						}
				}
				Text(resultUrl).font(.caption)
			   
			}header:{
				Text(item.header)
			}footer:{
				VStack(alignment: .leading){
					Text(item.footer)
					Divider()
						.background(Color.blue)
				}

			}
			
		   
		}
	   
	}
	
	private func health(item: PushServerModal)-> Bool{
		return true
	}
}






#Preview {
    ExampleView()
}
