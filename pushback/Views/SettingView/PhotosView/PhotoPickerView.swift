//
//  PhotoPickerView.swift
//  pushback
//
//  Created by He Cho on 2024/10/13.
//


import PhotosUI
import SwiftUI


struct PhotoPickerView:View {
	@Binding var draggImage:String?
	var imageSize:CGSize = .zero
	
	@State private var showPhotoPicker:Bool = false
	@State private var selectImage:[PhotosPickerItem] = []
	var body: some View {
		
		
		Button{
			self.showPhotoPicker.toggle()
		}label: {
			Image(systemName: "plus.viewfinder")
				.resizable()
				.padding(10)
				.frame(width: imageSize.width, height: imageSize.height)
				.symbolRenderingMode(.palette)
				.foregroundStyle( .tint, Color.primary)
				.dropDestination(for: Data.self) { items, location in
					if let _ = draggImage {
						self.draggImage = nil
						return false
					}
					Task.detached(priority: .high) {
						for item in items {
							if let image = UIImage(data: item){
								_ = await ImageManager.storeImage(from: UUID().uuidString, at: image)
							}
						}
						Toast.shared.present(title: String(localized: "保存成功"), symbol: "photo.badge.checkmark")
					}
					return true
				}
		}.photosPicker(isPresented: $showPhotoPicker, selection: $selectImage,matching: .images, preferredItemEncoding:.automatic)
			.onChange(of: selectImage) { newValue in
				debugPrint(selectImage)
				processPhoto(photos: selectImage)
			}
		
			
		
		
	}
	
	
	func processPhoto(photos: [PhotosPickerItem]){
		
		for photo in photos{
			photo.loadTransferable(type: Data.self) { result in
				switch result {
				case .success(let data):
					if let data{
						Task.detached(priority: .high){
							if let image = UIImage(data: data){
								_ = await ImageManager.storeImage(from: UUID().uuidString, at: image)
							}
							
						}
					}
					
				case .failure(let failure):
					print(failure)
				}
			}
		}
		Toast.shared.present(title: String(localized: "保存成功"), symbol: "photo.badge.checkmark")
		self.selectImage = []
		
	}
	
	
}
