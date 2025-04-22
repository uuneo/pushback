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
                    .textCase(.none)
                    
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
            
            PushExampleModel(header: AnyView(Text("点击右上角按钮可以复制测试URL、预览推送效果")),
                             footer: AnyView(Text( """
                                 ‼️参数可单独使用
                                 * /内容 或者 /标题/内容
                                 * group: 分组名，不传显示 `默认`
                                 * badge： 自定义角标 可选值 -1...
                                 * ttl: 消息保存时间 可选值 0...
                                 """)),
                           
                             title: AnyView(Text( "基本用法示例")),
                             params: String(localized: "标题/副标题/内容?group=默认&badge=1&ttl=1"),
                             index: 1),
            
            PushExampleModel(header: AnyView(Spacer()),
                             footer: AnyView(Text( "GET方法需要URIConponent编码")),
                             title: AnyView(Text( "Markdown样式")),
                             params: "?category=markdown&body=%23%20Pushback%0A%23%23%20Pushback%0A%23%23%23%20Pushback",
                             index: 2),
            
            PushExampleModel(header:
                                AnyView(
                                    HStack{
                                        Button{
                                            manager.messagePath.append(.sound)
                                            manager.allPath.append(.sound)
                                        }label:{
                                            Text("铃声列表")
                                                .font(.system(size: 12))
                                                .padding(.horizontal, 10)
                                        }
                                        Spacer()
                                    }
                                ),
                             footer: AnyView(Text( "可以为推送设置不同的铃声")),
                             title: AnyView(Text( "推送铃声")),
                             params: "\(String(localized: "推送内容"))?sound=craft",
                             index: 3),
            
            PushExampleModel(header:
                                AnyView(
                                    
                                    HStack{
                                        Button{
                                            manager.sheetPage = .cloudIcon
                                        }label:{
                                            Text("云图标")
                                                .font(.system(size: 12))
                                                .padding(.horizontal, 10)
                                        }
                                        
                                        Text( "自定义推送显示的logo")
                                        Spacer()
                                    }
                                ),
                             footer: AnyView(Spacer()),
                             title: AnyView(Text( "自定义icon")),
                             params:  "\(String(localized: "推送内容"))?icon=\(BaseConfig.iconRemote)",
                             index: 5),
            
            PushExampleModel(header: AnyView(Text("可对通知设置中断级别")),
                             footer: AnyView(Text( """
                             可选参数值:
                             - passive：仅添加到列表，不会亮屏提醒
                             - active： 默认值，系统会立即亮屏显示通知。
                             - timeSensitive:  时效性通知,专注模式下可显示通知。
                             - critical: ‼️重要提醒，静音或专注模式可正常提醒
                             * 参数可使用 0-10代替，具体查看文档
                             """)),
                             title: AnyView(Text( "通知类型")),
                             params: "\(String(localized:  "重要提醒通知,70%音量"))?level=critical&volume=7",
                             index: 6),
            
            
            PushExampleModel(header: AnyView(Text("URLScheme或者网址")),
                             footer: AnyView(Text( "点击跳转app")),
                             title: AnyView(Text("打开第三方App或者网站")),
                             params:  "\(String(localized: "推送内容"))?url=weixin://",
                             index: 7),
            
            
            
            PushExampleModel(header: AnyView(Text( "持续响铃")),
                             footer: AnyView(Text("通知铃声将持续播放30s，同时收到多个将按顺序依次响铃")),
                             title: AnyView(Text("持续响铃")),
                             params: "\(String(localized:  "持续响铃"))?call=1",
                             index: 8),
            
            PushExampleModel(header: AnyView(Text( "下拉消息会显示图片")),
                             footer: AnyView(Text( "携带一个image,会自动下载缓存")),
                             title:  AnyView(Text("携带图片")),
                             params:  "?title=\(String(localized: "标题" ))&body=\(String(localized: "内容" ))&image=\(BaseConfig.iconRemote)",
                             index: 9),
            
            
            PushExampleModel(header:
                                AnyView( HStack{
                                    Text( "需要在")
                                    Button{
                                        manager.messagePath.append(.crypto)
                                        manager.allPath.append(.privacyConfig)
                                        
                                    }label:{
                                        Text("算法配置")
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 10)
                                    }
                                    Text("中进行配置")
                                }),
                             footer: AnyView(Text( "加密后请求需要注意特殊字符的处理")),
                             title: AnyView(Text( "端到端加密推送")),
                             params: "?ciphertext=\(ciphertext)",
                             index: 10),
            
        ]
    }
    
    
}





#Preview {
    ExampleView()
}
