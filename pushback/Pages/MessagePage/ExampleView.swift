//
//  ExampleView.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import SwiftUI
import Defaults


struct ExampleView: View {
    @EnvironmentObject private var manager:PushbackManager
	@State private var username:String = ""
	@State private var title:String = ""
	@State private var pickerSelection:Int = 0
	@State private var showAlart = false
	@Default(.servers) var servers
	@Default(.cryptoConfig) var cryptoConfig
    
	var body: some View {
        List{
            if servers.count > 1{
                HStack{
                    Spacer()
                    Picker(selection: $pickerSelection, label: Text("切换服务器")) {
                        ForEach(servers.indices, id: \.self){index in
                            let server = servers[index]
                            Text(server.name)
                                .tag(server.id)
                        }
                    }.pickerStyle(MenuPickerStyle())

                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
           

            customHelpItemView()


        }.listStyle(GroupedListStyle())
            .toolbar{
                ToolbarItem {

                    Image(systemName: "headphones.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.tint, Color.primary)
                        .pressEvents(onRelease: { value in
                            manager.messagePath.append(.sound)
                        })
                }
                
                ToolbarItem{
                    Button{
                        PushbackManager.shared.sheetPage = .cloudIcon
                    }label:{
                        
                        ZStack{
                            Image(systemName: "icloud")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary)
                            Image(systemName: "photo")
                                .scaleEffect(0.4)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tint)
                                .offset(y: 2)
                        }
                    }
                }


            }
            .navigationTitle( "使用示例")
	}


	@ViewBuilder
	func customHelpItemView() -> some View{

		ForEach(createExample(cryptoData: cryptoConfig),id: \.id){ item in
			//			let server = servers[pickerSeletion >= servers.count ? 0 : pickerSeletion]
			let server = (pickerSelection >= 0 && pickerSelection < servers.count) ? servers[pickerSelection] : servers[0]
			let resultUrl = server.url + "/" + server.key + "/" +  item.params

			Section{
				HStack{
					item.title
						.font(.headline)
						.fontWeight(.bold)
					Spacer()
					Image(systemName: "doc.on.doc")

						.symbolRenderingMode(.palette)
						.foregroundStyle(.tint, Color.primary)
						.padding(.horizontal)
						.onTapGesture {
                            
							UIPasteboard.general.string = resultUrl

							Toast.copy(title: String(localized:  "复制成功"))
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
			PushExampleModel(header: AnyView(Text("最基本用法示例")),
							 footer: AnyView(Text( "点击右上角按钮可以复制测试URL、预览推送效果\nSafari有缓存，没收到推送时请刷新页面")),
							 title: AnyView(Text( "内容")),
							 params: String(localized: "推送内容"),
							 index: 1),

			PushExampleModel(header: AnyView(Text(  "推送标题加内容")),
							 footer: AnyView(Text("推送标题的字号比推送内容粗一点")),
							 title: AnyView(Text( "标题 + 内容")),
							 params: String(localized: "标题/内容"),
							 index: 2),

			PushExampleModel(header: AnyView(Text("静音或专注模式可正常提醒")),
							 footer: AnyView(Text("可选参数值: 3～10代表音量30～100% ")),
							 title: AnyView(
								HStack{
									Image(systemName: "exclamationmark.triangle.fill")
										.resizable()
										.scaledToFit()
										.frame(width: 15)
										.symbolRenderingMode(.palette)
										.foregroundStyle(.white, .red)
									Text("重要提醒")
								}

							 ),
							 params: "\(String(localized:  "重要提醒通知,70%音量"))?level=critical&volume=7",
							 index: 3),

			PushExampleModel(header: AnyView(Text("可对通知设置中断级别")),
							 footer: AnyView(Text( """
 可选参数值:
 * passive 或 0：仅添加到列表，不会亮屏提醒
 * active 或 1： 默认值，系统会立即亮屏显示通知。
 * timeSensitive 或 2:  时效性通知,专注模式下可显示通知。
 """)),
							 title: AnyView(Text( "通知类型")),
							 params: "\(String(localized:  "时效性通知"))?level=timeSensitive",
							 index: 4),


			PushExampleModel(header: AnyView(Text( "右上角点击耳机查看所有铃声")),
							 footer: AnyView(Text( "可以为推送设置不同的铃声")),
							 title: AnyView(Text( "推送铃声")),
							 params: "\(String(localized: "推送内容"))?sound=craft",
							 index: 5),

			PushExampleModel(header: AnyView(Text( "自定义推送显示的logo")),
							 footer: AnyView(Spacer()),
							 title: AnyView(Text( "自定义icon")),
							 params:  "\(String(localized: "推送内容"))?icon=\(BaseConfig.iconRemote)",
							 index: 6),

			PushExampleModel(header: AnyView(Text( "下拉消息会显示图片")),
							 footer: AnyView(Text( "携带一个image,会自动下载缓存")),
							 title:  AnyView(Text("携带图片")),
							 params:  "?title=\(String(localized: "标题" ))&body=\(String(localized: "内容" ))&image=\(BaseConfig.iconRemote)",
							 index: 7),

			PushExampleModel(header: AnyView(Text( "只能在消息提醒查看,不自动缓存")),
							 footer: AnyView(Text( "携带一个video，点击自动播放")),
							 title: AnyView(Text("携带视频")),
							 params: "?title=\(String(localized: "标题"))&body=\(String(localized: "内容" ))&video=\(BaseConfig.defaultVideo)",
							 index: 8 ),


			PushExampleModel(header: AnyView(Spacer()),
							 footer: AnyView(Text( "如果要使用这个参数，设置中的角标模式需要设置成自定义")),
							 title: AnyView(Text("自定义角标")),
							 params:  "\(String(localized:  "自定义角标"))?badge=1",
							 index: 9),

			PushExampleModel(header: AnyView(Text("消息保存时间")),
							 footer: AnyView(Text( "ttl=天数 0代表不保存，默认值需在app内设置")),
							 title: AnyView(Text("保存1天示例")),
							 params: "\(String(localized:"推送内容" ))?ttl=1",
							 index: 10),

			PushExampleModel(header: AnyView(Text("URLScheme或者网址")),
							 footer: AnyView(Text( "点击跳转app")),
							 title: AnyView(Text("打开第三方App或者网站")),
							 params:  "\(String(localized: "推送内容"))?url=weixin://",
							 index: 11),

			PushExampleModel(header: AnyView(Text( "默认分组名：默认")),
							 footer: AnyView(Text( "推送将按照group参数分组显示在通知中心和应用程序内")),
							 title: AnyView(Text("推送消息分组")),
							 params:  "\(String(localized: "推送消息分组"))?group=\(String(localized: "测试"))",
							 index: 12),

			PushExampleModel(header: AnyView(Text( "持续响铃")),
							 footer: AnyView(Text("通知铃声将持续播放30s，同时收到多个将按顺序依次响铃")),
							 title: AnyView(Text("持续响铃")),
							 params: "\(String(localized:  "持续响铃"))?call=1",
							 index: 13),


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
							 title: AnyView(Text( "推送加密")),
							 params: "?ciphertext=\(ciphertext)",
							 index: 14),

		]
	}


}





#Preview {
	ExampleView()
}
