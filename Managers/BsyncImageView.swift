//
//  BsyncView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//


import SwiftUI
import Defaults



struct AvatarView: View {
	
	var id:String?
	var icon:String?
	var mode:String?
	
	@Default(.appIcon) var appicon
	
	@State private var success:Bool = true
	@State private var image: UIImage?
	
	
	var body: some View {
		GeometryReader {
			let size = $0.size
			
			VStack{
				if let icon = icon, icon.isValidURL() == .remote, success{
					if let image = image {
						// 如果已经加载了图片，则显示图片
						Image(uiImage: image)
							.resizable()
							.frame(width: size.width, height: size.height)
						
					} else {
						// 如果图片尚未加载，则显示加载中的视图
						ProgressView()
							.frame(width: size.width, height: size.height)
							.onAppear{
								Task.detached {
									await loadImage(icon: icon)
								}
							}
						
					}
				}else{
					if mode == "1"{
						Image(AppIconEnum.def.logo)
							.resizable()
							.frame(width: size.width, height: size.height)
					}else{
						Image(appicon.logo)
							.resizable()
							.frame(width: size.width, height: size.height)
					}
				}
				
			}
			.aspectRatio(contentMode: .fill )
			
		}
		
		
	}
	
	private func loadImage(icon:String ) async {
		if let imagePath = await ImageManager.fetchImage(from: icon) {
			await MainActor.run {
				self.image = UIImage(contentsOfFile: imagePath)
			}
		} else {
			await MainActor.run {
				self.success = false
			}
		}
	}
}
