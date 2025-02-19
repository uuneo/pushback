//
//  File name:     PrivacySecureView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/11.
	

import SwiftUI
import Defaults

struct PrivacySecureView: View {
	@Default(.defaultBrowser) var defaultBrowser
	
    var body: some View {
		NavigationStack{
			List{


				Section(header: Text("默认浏览器设置")){
					HStack{
						Picker(selection: $defaultBrowser) {
							ForEach(DefaultBrowserModel.allCases, id: \.self) { item in
								Text(item.title)
									.tag(item)
							}
						}label:{
							Text("默认浏览器")
						}.pickerStyle(SegmentedPickerStyle())

					}
				}

				Section(header: Text("端到端加密")){

					NavigationLink{
						CryptoConfigView()
					}label: {
						Label {
							Text( "算法配置")
						} icon: {
							Image(systemName: "bolt.shield")
								.scaleEffect(0.9)
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
						}
					}

				}



			}
			.navigationTitle("隐私与安全")
			

		}

	}


}

#Preview {
    PrivacySecureView()
}
