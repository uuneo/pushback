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
    
    @EnvironmentObject private var manager:AppManager
    
    var response: (String) async-> Bool
    
	var body: some View {
		ZStack{

            QRScanner(restart: $restart, flash: $torchIsOn) { code in
                Task{
                    if await response(code) {
                        self.dismiss()
                    }else{
                        self.showActive.toggle()
                    }
                }
                
            } fail: { error in
                switch error{
                case .unauthorized(let status):
                    if status != .authorized{
                        Toast.info(title:  "没有相机权限")
                    }
                    self.dismiss()
                default:
                    Toast.error(title: "扫码失败")
                    self.dismiss()
                }
                
            }
            .actionSheet(isPresented: $showActive) {
                ActionSheet(title: Text( "扫码成功"),buttons: [
                    .default(Text( "重新扫码"), action: {
                        self.showActive = false
                        self.restart.toggle()
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
                        .font(.body.bold())
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
                
                VStack{
                    Image(systemName: torchIsOn ? "bolt" : "bolt.slash")
                        .scaleEffect(3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.accent,.ultraThinMaterial)
                        .symbolEffect(.replace)
                        .padding()
                        .pressEvents(onRelease: { _ in
                            self.torchIsOn.toggle()
                            return true
                        })
                    
                }
                .padding(.bottom, 80)
				


			}

		}.ignoresSafeArea()
	}

}




#Preview {
    ScanView(){_ in  true }
}


