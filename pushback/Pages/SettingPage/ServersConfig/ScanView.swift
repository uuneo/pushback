//
//  ScanView.swift
//  Meow
//
//  Created by uuneo 2024/8/10.
//


import SwiftUI
import AVFoundation
import QRScanner
import UIKit

struct ScanView: View {
	@Environment(\.dismiss) var dismiss
	@State private var torchIsOn = false
	@State private var restart = false
	@State private var showActive = false
	@State private var status:AVAuthorizationStatus = .authorized
	var startConfig: (String)->Void
	var body: some View {
		ZStack{

			QRScanner(restart: $restart, flash: $torchIsOn) { code in
				if code.isValidURL() == .remote{
					startConfig(code)
					self.dismiss()
				}else{
					self.showActive = true
				}
			} fail: { error in
				switch error{
					case .unauthorized(let status):
						self.status = status
					default:
						self.status = .denied
				}
			}
			.actionSheet(isPresented: $showActive) {


				ActionSheet(title: Text( "不正确的地址"),buttons: [

					.default(Text( "重新扫码"), action: {
						self.restart.toggle()
						self.showActive = false
					}),

						.cancel({
							self.dismiss()
						})
				])
			}



			VStack{
				HStack{

					Spacer()
					Image(systemName: "xmark")
						.font(.system(size: 17, weight: .bold))
						.foregroundColor(.secondary)
						.padding(8)
						.background(.ultraThinMaterial, in: Circle())
						.backgroundStyle(cornerRadius: 18)
						.onTapGesture {
							self.dismiss()
						}

				}
				.padding()
				.padding(.top,50)
				Spacer()

				Button{
					self.torchIsOn.toggle()
				}label: {
					Image(systemName: "flashlight.\(torchIsOn ? "on" : "off").circle")
						.font(.system(size: 50))
						.padding(.bottom, 80)
				}


			}

		}.ignoresSafeArea()
	}
}




#Preview {
	ScanView { _ in

	}
}


