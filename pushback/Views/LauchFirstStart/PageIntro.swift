//
//  PageIntro.swift
//  Intro+Login
//
//  Created by Balaji on 30/03/23.
//

import SwiftUI

/// Page Intro Model
struct PageIntro: Identifiable, Hashable {
    var id: UUID = .init()
    var introAssetImage: String
    var title: String
    var subTitle: String
    var displaysAction: Bool = false
}

var pageIntros: [PageIntro] = [
    .init(introAssetImage: "Page 1", title: "允许必要的权限", subTitle: "网络权限用来获取苹果提送密钥和通知权限用来接收通知."),
    .init(introAssetImage: "Page 2", title: "文字、图片、视频\n轻松推送到手机", subTitle: "任意浏览器，脚本语言都可以把内容发送到您的手机上,会上网就会使用."),
    .init(introAssetImage: "Page 3", title: "不需要任何的设置\n 打开即用", subTitle: "每个月需要打开一次App用来更新设备推送密钥.", displaysAction: true),
]

struct CustomIndicatorView: View {
	/// View Properties
	var totalPages: Int
	var currentPage: Int
	var activeTint: Color = .black
	var inActiveTint: Color = .gray.opacity(0.5)
	var body: some View {
		HStack(spacing: 8) {
			ForEach(0..<totalPages, id: \.self) {
				Circle()
					.fill(currentPage == $0 ? activeTint : inActiveTint)
					.frame(width: 4, height: 4)
			}
		}
	}
}
