//
//  File name:     CrashReportView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/27.
	

import SwiftUI

struct CrashReportView: View {
	@Environment(\.dismiss) var dismiss
	let crashLog: String

	var body: some View {

		NavigationStack{
			VStack{
				VStack(alignment: .leading){
					HStack{
						Spacer()
						Text("可能需要重启APP！")
							.font(.title)
							.foregroundStyle(.red)
						Spacer()
					}
					.padding(.vertical)
					.fontWeight(.bold)
					Text("App不会获取任何程序日志 如您需要帮助，复制日志发给我")
					Text("Telegram: https://t.me/+pmCp6gWuAzFjYWQ1")
					Text(String(localized: "邮箱") + ":to@uuneo.com")
				}
				.font(.system(size: 14))
				.padding()

				ScrollView {

					Text(crashLog)
						.padding()
						.font(.system(.body, design: .monospaced))
						.foregroundColor(.primary)
				}
				.frame(maxHeight: UIScreen.main.bounds.height / 3)
				Spacer()
				HStack{
					Spacer()
					Button{
						PushbackManager.shared.copy(crashLog)
						Toast.shared.present(title: String(localized: "复制成功"), symbol: .success)
						self.dismiss()
					}label: {
						Text("复制崩溃日志")
							.padding(.trailing, 30)
					}
				}.padding()
				Spacer()
			}
			.navigationTitle("崩溃报告")
			.navigationBarTitleDisplayMode(.inline)

		}


	}
}

#Preview {
	CrashReportView(crashLog: "没有数据")

}
