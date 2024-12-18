//
//  uAsyncImage.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
//


import SwiftUI

struct uAsyncImage:View {
	var imageCache:ImageCacheModel
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
							
							if let localPath = imageCache.localPath,
							   let uiimage = UIImage(contentsOfFile: localPath.path) {
								if isThumbnail,
								   let preview = uiimage.preparingThumbnail(of: .init(width: max(uiimage.size.width / 5, size.width * 2), height: max(uiimage.size.height / 5, size.height * 2))){

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
								debugPrint("error",imageCache.name)
								await MainActor.run {
									self.phase = .failure( StringError( "Not Image"))
								}
							}
						}
					}
				
			case .success(let image):
				if isDragg{
					image
						.resizable()
						.customDraggable(300, appear: { item in
							completion?(imageCache.name)
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
