//
//  File name:     PaywallView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/23.


import SwiftUI
import StoreKit

struct PaywallView: View {
	@Environment(\.dismiss) var dismiss
	@EnvironmentObject var store:AppState
	@State private var selectProduct:Product?
	@State private var buyStatus:Bool = false
	@State private var openUrl:String?

	var body: some View {
		NavigationStack{
			VStack{


				HStack{
					Text("获取开发者持续支持")
						.font(.title3)
						.foregroundStyle(.gray)
						.padding(.leading, 25)
					Spacer()
				}
				.padding(.bottom)

				HStack{
					Spacer()
					ForEach(store.products, id: \.id) { product in
						Button {
							Task {
								self.selectProduct = product
								debugPrint(product)
							}
						} label: {
							VStack {

								Text(verbatim: product.displayPrice)
									.font(.title)
									.fontWeight(.bold)
									.foregroundStyle(.primary)
								Text(verbatim: product.description)
									.font(.headline)
									.foregroundStyle(.gray)

							}
							.onAppear{
								if product == store.products.first{
									self.selectProduct = store.products.first
								}
							}
							.frame(width: 150, height: 130, alignment: .center)
							.background(
								RoundedRectangle(cornerRadius: 20)
									.stroke(selectProduct == product ? Color.green : Color.gray, lineWidth: 3)
									.background(.background)
									.clipped()

							)

						}
						Spacer()
					}
				}




				HStack{

					Button{
						Task{
							self.buyStatus = true
							if let selectProduct{
								try await  store.purchase(selectProduct)
								self.dismiss()
							}

							self.buyStatus = false

						}
					}label:{
						RoundedRectangle(cornerRadius: 20)
							.fill(.tint)
							.frame(width: UIScreen.main.bounds.width - 20, height: 50, alignment: .center)
							.overlay {
								if buyStatus{
									HStack{
										ProgressView()
											.progressViewStyle(CircularProgressViewStyle())
									}
								}else{
									Text("开启计划")
										.fontWeight(.bold)
										.foregroundStyle(.white)
								}
							}
					}
					.disabled(buyStatus)


				}

				.padding(.vertical)

				Spacer()

				HStack(spacing: 20){
					Spacer()
					Button{
						self.openUrl = BaseConfig.privacyURL
					}label: {
						Text("隐私政策")
					}
					Button{
						self.openUrl = BaseConfig.userAgreement
					}label: {
						Text("用户协议")
					}
					Button{
						Task{
							await store.restorePurchases()
						}
					}label: {
						Text("恢复购买")
					}

					Spacer()
				}
				.padding(.bottom)
				.font(.caption)
				.fullScreenCover(isPresented: Binding(get: {
					openUrl != nil
				}, set: { value in
					openUrl = nil
				})) {
					if let openUrl{
						SFSafariView(url: openUrl)
							.ignoresSafeArea()
					}
					
				}


			}
			.navigationTitle("来杯咖啡，支持一下!")
			.navigationBarTitleDisplayMode(.large)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(action: {
						self.dismiss()
					}, label: {
						Image(systemName: "arrow.left")
							.font(.title2)
							.foregroundStyle(.gray)
					})
				}
			}

		}.presentationDetents([.medium])
	}
}

#Preview {
	NavigationStack{
		SettingsView()
			.environmentObject(PushbackManager.shared)
			.environmentObject(AppState())
	}
}
