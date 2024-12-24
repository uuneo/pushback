//
//  ImageDetailView.swift
//  pushback
//
//  Created by He Cho on 2024/10/16.
//
import SwiftUI
import RealmSwift

struct ImageDetailView:View {
	var image: ImageModel
	@Binding var imageUrl:ImageModel?
	@State var draggImage:String? = nil

	@State private var showSheet:Bool = false
	@State private var showSlideView:Bool = true
	let viewbounds = UIScreen.main.bounds
	var body: some View {
		
		ZStack{
			
			ToolsSlideView(show: $showSlideView){

				uAsyncImage(imageUrl: image.url, size: CGSize(width: viewbounds.width  - 20, height: viewbounds.height * 0.8), mode: .fit, isThumbnail: false)
				
			}dismiss: {
				self.imageUrl = nil
			}leftButton: {
				self.showSheet.toggle()
			}
			
			
			
		}
		.sheet(isPresented: $showSheet){
			ChangeKeyImageKey(image: image)
		}
		
	}

}




