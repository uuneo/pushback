//
//  uAsyncImage.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
//


import SwiftUI

struct uAsyncImage:View {
	var url:String
	var size:CGSize
	var mode: ContentMode = .fill
	var isDragg:Bool = true
	var isThumbnail:Bool = true
	var completion: ((String?)-> Void)? = nil
	@State private var phase: AsyncImagePhase = .empty
	
	
	var body: some View {
		ZStack{
			switch phase {
				
			case .empty:
				ProgressView()
					.scaleEffect(1.5)
					.frame(width: size.width, height: size.height)
					.onAppear{
						Task.detached(priority: .medium) {
							
							if let fileUrl = await ImageManager.fetchImage(from: url),
							   let uiimage = UIImage(contentsOfFile: fileUrl) {
								if isThumbnail,
								   let preview = uiimage.preparingThumbnail(of: .init(width: max(uiimage.size.width / 10, size.width), height: max(uiimage.size.height / 10, size.height))){
									
									await MainActor.run {
										self.phase = .success(Image(uiImage: preview))
									}
									
								}else{
									await MainActor.run {
										self.phase = .success(Image(uiImage: uiimage))
									}
								}
								
								return
							}else{
								debugPrint("error",url)
								await MainActor.run {
									self.phase = .failure("Not Image")
								}
							}
							
							
							
							
							if let fileUrl = await ImageManager.fetchImage(from: url),
							   let uiimage = UIImage(contentsOfFile: fileUrl),
							   let preview = uiimage.preparingThumbnail(of: .init(width: uiimage.size.width / 5, height: uiimage.size.height / 5))
							{
								await MainActor.run {
								
									self.phase = .success(Image(uiImage: preview))
								}
								return
							}else{
								debugPrint("error",url)
								await MainActor.run {
									self.phase = .failure("Not Image")
								}
							}
						}
					}
				
			case .success(let image):
				if isDragg{
					image
						.resizable()
						.customDraggable(300, appear: { item in
							completion?(url)
						})
						.aspectRatio(contentMode: mode)
						.frame(width: min(size.width, size.height))
						
				}else{
					image
						.resizable()
						.aspectRatio(contentMode: mode)
						.frame(width: min(size.width, size.height))
				}
				
				
			case .failure(_):
				Image("failImage")
					.resizable()
					.aspectRatio(contentMode: mode)
					.frame(width: size.width)
					.frame(width: min(size.width, size.height))
					
			@unknown default:
				Image("failImage")
					.resizable()
					.aspectRatio(contentMode: mode)
					.frame(width: min(size.width, size.height))
					
			}
		}
		.onDisappear{
			self.phase = .empty
		}
		
			
	
	}
}
