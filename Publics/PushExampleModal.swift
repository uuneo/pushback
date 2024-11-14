//
//  PushExampleModal.swift
//  pushback
//
//  Created by He Cho on 2024/10/26.
//

import Foundation

struct PushExample:Identifiable {
	var id = UUID().uuidString
	var header,footer,title,params:String
	var index:Int
	
	static let datas:[PushExample] = [
		PushExample(header: String(localized:  "示例 1"),
					footer: String(localized:  "点击右上角按钮可以复制测试URL、预览推送效果\nSafari有缓存，没收到推送时请刷新页面"),
					title: String(localized: "推送内容"),
					params: String(localized: "推送内容"),
					index: 1),
		
		PushExample(header: String(localized:  "示例 2"),
					footer: String(localized:  "推送标题的字号比推送内容粗一点"),
					title: String(localized: "标题 + 内容"),
					params: String(localized: "标题/内容"),
					index: 2),
		
		PushExample(header: String(localized:  "右上角点击耳机查看所有铃声"),
					footer: String(localized:  "可以为推送设置不同的铃声"),
					title: String(localized:  "推送铃声"),
					params: "\(String(localized: "推送内容"))?sound=minuet",
					index: 3),
		
		PushExample(header: String(localized:  "自定义推送显示的logo"),
					footer: String(localized:  "可以自定义icon=https://图片网址"),
					title: String(localized:  "自定义icon"),
					params:  "\(String(localized: "推送内容"))?icon=https://day.app/assets/images/avatar.jpg",
					index: 4),
		
		PushExample(header: String(localized:  "自动缓存,app内外都可以查看"),
					footer: String(localized:  "携带一个image"),
					title: String(localized:  "携带图片"),
					params:  "?title=\(String(localized: "标题" ))&body=\(String(localized: "内容" ))&image=https://day.app/assets/images/avatar.jpg",
					index: 5),
		
		PushExample(header: String(localized:  "只能在消息提醒查看,不自动缓存"),
					footer: String(localized:  "携带一个video，点击自动播放"),
					title: String(localized: "携带视频"),
					params: "?title=\(String(localized: "标题"))&body=\(String(localized: "内容" ))&video=https://sf1-cdn-tos.huoshanstatic.com/obj/media-fe/xgplayer_doc_video/mp4/xgplayer-demo-360p.mp4",
					index: 6 ),
		
		PushExample(header: "",
					footer: String(localized: "如果要使用这个参数，设置中的角标模式需要设置成自定义"),
					title: String(localized: "自定义角标"),
					params:  "\(String(localized:  "自定义角标"))?badge=1",
					index: 7),
		
		PushExample(header: String(localized: "自动保存"),
					footer: String(localized:  "消息默认保存，除非携带isArchive=0，信息不会在前台出现"),
					title: String(localized:  "不保存消息"),
					params: "\(String(localized:"推送内容" ))?isArchive=0",
					index: 8),
		
		PushExample(header: "URLScheme\(String(localized: "或者网址"))",
					footer: String(localized: "点击跳转app"),
					title: String(localized: "打开第三方App或者网站"),
					params:  "\(String(localized: "推送内容"))?icon=weixin&url=weixin://",
					index: 9),
		
		PushExample(header: String(localized: "默认分组名：信息"),
					footer: String(localized: "推送将按照group参数分组显示在通知中心和应用程序内"),
					title: String(localized: "推送消息分组"),
					params:  "\(String(localized: "推送消息分组"))?group=\(String(localized: "测试"))",
					index: 10),
		
		PushExample(header: String(localized: "持续响铃"),
					footer: String(localized:"通知铃声将持续播放30s，同时收到多个将按顺序依次响铃"),
					title: String(localized:  "持续响铃"),
					params: "\(String(localized:  "持续响铃"))?call=1",
					index: 11),
		
		PushExample(header: String(localized:  "可对通知设置中断级别"),
					footer:  """
\(String(localized: "可选参数值"))：
level=active: \(String(localized: "默认值，系统会立即亮屏显示通知。" )) 
*  \(String(localized: "支持数字 level=-1 小于0 都代表 active" ))
level=timeSensitive:  \(String(localized: "时效性通知,专注模式下可显示通知。" ))
*  \(String(localized: "支持数字 level=0" ))
level=passive：  \(String(localized: "仅添加到列表，不会亮屏提醒" ))
*  \(String(localized: "支持数字 level=1" ))
level=critical:  \(String(localized: "重要提醒，静音或专注模式可正常提醒" ))
*  \(String(localized: "支持数字(2-10) level=2 声音最小 level=10 声音最大 " ))
""",
					title: String(localized:  "通知类型"),
					params: "\(String(localized:  "时效性通知"))?level=timeSensitive",
					index: 12),
		
		PushExample(header: String(localized: "需要在设置>算法设置中进行配置"),
					footer: String(localized: "发送和接收时对推送内容进行加密和解密"),
					title: String(localized: "推送加密"),
					params: "?ciphertext=\(String(localized:  "加密后的数据"))",
					index: 13),
		
	]
	
	
}

