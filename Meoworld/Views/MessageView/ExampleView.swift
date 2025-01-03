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
	@State private var pickerSelection:Int = 0
	@State private var showAlart = false
	@Default(.servers) var servers
	@Default(.cryptoConfig) var cryptoConfig
	@AppStorage("abc") var name:String = ""
	var body: some View {
		NavigationStack{
			
			List{
				
				HStack{
					Spacer()
					Picker(selection: $pickerSelection, label: Text("切换服务器")) {
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
							SoundView()
								.toolbar(.hidden, for: .tabBar)
						} label: {
							Image(systemName: "headphones.circle")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
							
						}
					}
					
					
				}
				.navigationTitle( "使用示例")
			
		}
	}
	
	
	@ViewBuilder
	func customHelpItemView() -> some View{
		
		ForEach(createExample(cryptoData: cryptoConfig),id: \.id){ item in
			//			let server = servers[pickerSeletion >= servers.count ? 0 : pickerSeletion]
			let server = (pickerSelection >= 0 && pickerSelection < servers.count) ? servers[pickerSelection] : servers[0]
			let resultUrl = server.url + "/" + server.key + "/" +  item.params
			
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
							if resultUrl.isValidURL() == .remote, let url = URL(string: resultUrl) {
								
								UIApplication.shared.open(url)
							}
						}
				}
				Text(resultUrl).font(.caption)
				
			}header:{
				item.header
			}footer:{
				VStack(alignment: .leading){
					item.footer
					Divider()
						.background(Color.blue)
				}
				
			}
			
			
		}
		
	}
	
}


extension ExampleView{
	func createExample(cryptoData:CryptoModel)-> [PushExampleModel]{

		let data = CryptoManager(cryptoData).encrypt(BaseConfig.testData)
		/// 加号害人啊！！！！！！！！！！！！！！
		let ciphertext = data?.base64EncodedString().replacingOccurrences(of: "+", with: "%2B") ?? ""
		
		
		return [
			PushExampleModel(header: AnyView(Text("示例 1")),
							 footer: AnyView(Text( "点击右上角按钮可以复制测试URL、预览推送效果\nSafari有缓存，没收到推送时请刷新页面")),
							 title: String(localized: "推送内容"),
							 params: String(localized: "推送内容"),
							 index: 1),
			
			PushExampleModel(header: AnyView(Text(  "示例 2")),
							 footer: AnyView(Text("推送标题的字号比推送内容粗一点")),
							 title: String(localized: "标题 + 内容"),
							 params: String(localized: "标题/内容"),
							 index: 2),
			
			PushExampleModel(header: AnyView(Text( "右上角点击耳机查看所有铃声")),
							 footer: AnyView(Text( "可以为推送设置不同的铃声")),
							 title: String(localized:  "推送铃声"),
							 params: "\(String(localized: "推送内容"))?sound=tuola",
							 index: 3),
			
			PushExampleModel(header: AnyView(Text( "自定义推送显示的logo")),
							 footer: AnyView(Spacer()),
							 title: String(localized:  "自定义icon"),
							 params:  "\(String(localized: "推送内容"))?icon=\(BaseConfig.iconRemote)",
							 index: 4),
			
			PushExampleModel(header: AnyView(Text( "下拉消息会显示图片")),
							 footer: AnyView(Text( "携带一个image,会自动下载缓存")),
							 title: String(localized:  "携带图片"),
							 params:  "?title=\(String(localized: "标题" ))&body=\(String(localized: "内容" ))&image=\(BaseConfig.iconRemote)",
							 index: 5),
			
			PushExampleModel(header: AnyView(Text( "只能在消息提醒查看,不自动缓存")),
							 footer: AnyView(Text( "携带一个video，点击自动播放")),
							 title: String(localized: "携带视频"),
							 params: "?title=\(String(localized: "标题"))&body=\(String(localized: "内容" ))&video=https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4",
							 index: 6 ),
			
			PushExampleModel(header: AnyView(Spacer()),
							 footer: AnyView(Text( "如果要使用这个参数，设置中的角标模式需要设置成自定义")),
							 title: String(localized: "自定义角标"),
							 params:  "\(String(localized:  "自定义角标"))?badge=1",
							 index: 7),
			
			PushExampleModel(header: AnyView(Text("消息保存时间")),
							 footer: AnyView(Text( "ttl=天数 0代表不保存，默认值需在app内设置")),
							 title: String(localized:  "不保存消息"),
							 params: "\(String(localized:"推送内容" ))?ttl=0",
							 index: 8),
			
			PushExampleModel(header: AnyView(Text("URLScheme或者网址")),
							 footer: AnyView(Text( "点击跳转app")),
							 title: String(localized: "打开第三方App或者网站"),
							 params:  "\(String(localized: "推送内容"))?url=weixin://",
							 index: 9),
			
			PushExampleModel(header: AnyView(Text( "默认分组名：默认")),
							 footer: AnyView(Text( "推送将按照group参数分组显示在通知中心和应用程序内")),
							 title: String(localized: "推送消息分组"),
							 params:  "\(String(localized: "推送消息分组"))?group=\(String(localized: "测试"))",
							 index: 10),
			
			PushExampleModel(header: AnyView(Text( "持续响铃")),
							 footer: AnyView(Text("通知铃声将持续播放30s，同时收到多个将按顺序依次响铃")),
							 title: String(localized:  "持续响铃"),
							 params: "\(String(localized:  "持续响铃"))?call=1",
							 index: 11),
			
			PushExampleModel(header: AnyView(Text("可对通知设置中断级别")),
							 footer: AnyView(Text( """
 可选参数值：(level=0...10)可用数字代替 3-10 代表音量
 level=passive(0)：仅添加到列表，不会亮屏提醒
 level=active(1): 默认值，系统会立即亮屏显示通知。
 level=timeSensitive(1):  时效性通知,专注模式下可显示通知。
 level=critical(3-10): 重要提醒，静音或专注模式可正常提醒
 """)),
							 title: String(localized:  "通知类型"),
							 params: "\(String(localized:  "时效性通知"))?level=timeSensitive",
							 index: 12),
			
			PushExampleModel(header: AnyView(
				HStack{
					Text( "需要在")
					NavigationLink{ CryptoConfigView() }label: {
						Text("算法配置")
							.font(.system(size: 12))
					}
					Text("中进行配置")
				}),
							 footer: AnyView(Text( "加密后请求需要注意特殊字符的处理")),
							 title: String(localized: "推送加密"),
							 params: "?ciphertext=\(ciphertext)",
							 index: 13),
			
		]
	}
	
	
}





#Preview {
	ExampleView()
}
