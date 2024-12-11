//
//  File name:     PrivacySecureView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/11.
	

import SwiftUI

struct PrivacySecureView: View {
	@State private var showCrypto:Bool = false
    var body: some View {
		NavigationStack{
			List{
				Section{
					Button{
						self.showCrypto.toggle()
					}label: {
						HStack{
							Label {
								Text( "算法配置")
							} icon: {
								Image(systemName: "bolt.shield")
									.scaleEffect(0.9)
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
							}
							Spacer()
							Image(systemName: "chevron.right")
								.foregroundStyle(.gray)
						}

					}
				}
				.sheet(isPresented: $showCrypto) {
					CryptoConfigView()
				}
			}
			.navigationTitle("隐私与安全")
		}
    }
}

#Preview {
    PrivacySecureView()
}
