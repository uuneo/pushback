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
    
    var response: (String)async-> Bool

    
	var body: some View {
		ZStack{
            let config = QRScannerView.Input(focusImage: UIImage(named: "scan"),focusImagePadding: 20, isBlurEffectEnabled: true)

            QRScanner(rescan: $restart, flash: $torchIsOn, isRuning: true, input: config) { code in

                Task{@MainActor in
                    AudioServicesPlaySystemSound(1052)
                    self.showActive = await response(code)
                }

            } onFailure: { error in
                AudioServicesPlaySystemSound(1053)
                switch error{
                case .unauthorized(let status):
                    if status != .authorized{
                        Toast.info(title:  "没有相机权限")
                    }
                default:
                    Toast.error(title: "扫码失败")
                }
                self.showActive = true
            }
            .actionSheet(isPresented: $showActive) {
                ActionSheet(title: Text( "扫码提示!"),buttons: [
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
                        // TODO: - 待修改
                        .onTapGesture {
                            self.dismiss()
                            Haptic.impact()
                        }

				}
				.padding()
				.padding(.top,50)
				Spacer()
                
                VStack{
                    Image(systemName: torchIsOn ? "bolt" : "bolt.slash")
                        .scaleEffect(3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.accent,.ultraThinMaterial)
                        .symbolEffect(.replace)
                        .padding()
                        .VButton(onRelease: { _ in
                            self.torchIsOn.toggle()
                            return true
                        })
                    
                }
                .padding(.bottom, 80)
				


			}

		}
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onChanged({ active in
                    Haptic.selection()
                })
                .onEnded({ action in
                   
                    if  action.translation.height > 100{
                        manager.fullPage = .none
                        Haptic.impact()
                    }
                })
        )
	}

    func showMenu(){
        self.showActive = true
    }

}




#Preview {
    ScanView(){_ in true}
}




