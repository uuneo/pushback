//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by He Cho on 2024/10/26.
//

import UIKit
import Social
import SwiftUI

class ShareViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		/// Interactive Dismiss Disabled
		isModalInPresentation = true
		
		if let itemProviders = (extensionContext!.inputItems.first as? NSExtensionItem)?.attachments {
			let hostingView = UIHostingController(rootView: ShareView(itemProviders: itemProviders, extensionContext: extensionContext))
			hostingView.view.frame = view.frame
			view.addSubview(hostingView.view)
		}
	}
}

fileprivate struct ShareView: View {
	var itemProviders: [NSItemProvider]
	var extensionContext: NSExtensionContext?
	/// View Properties
	@State private var items: [Item] = []
	var body: some View {
		GeometryReader {
			let size = $0.size
			Spacer()
			VStack(spacing: 15) {
				Text( "添加到APP")
					.font(.title3.bold())
					.frame(maxWidth: .infinity)
					.overlay(alignment: .leading) {
						Button( "取消", action: dismiss)
							.tint(.red)
					}
					.padding(.bottom, 10)
		
				
				ScrollView(.horizontal) {
					LazyHStack(spacing: 0) {
						ForEach(items, id: \.id) { item in
							VStack{
								Image(uiImage: item.previewImage)
									.resizable()
									.aspectRatio(contentMode: .fit)
									.padding(.horizontal, 15)
									.frame(width: size.width)
								
								TextField( "输入图片Key", text: Binding(get: {
									item.id
								}, set: { value in
									if let index = items.firstIndex(where: {$0.id == item.id}){
										items[index].id = value
									}
								}))
								.customField(icon: "square.and.pencil.circle")
								.padding(.horizontal)
							}
							.frame(width: size.width)
						}
					}
				}
				.frame(height: 500)
				.scrollIndicators(.hidden)
				.scrollTargetBehavior(.paging)
				.padding(.horizontal, -15)
				
				/// Save Button
				Button(action: saveItems, label: {
					Text( "保存")
						.font(.title3)
						.fontWeight(.semibold)
						.padding(.vertical, 10)
						.frame(maxWidth: .infinity)
						.foregroundStyle(.white)
						.background(.blue, in: .rect(cornerRadius: 10))
						.contentShape(.rect)
				})
				
				Spacer(minLength: 0)
				
			}
			.padding(15)
			.onAppear(perform: {
				extractItems(size: size)
			})
		}
	}
	
	/// Extracting Image Data and Creating Thumbnail Preview Images
	func extractItems(size: CGSize) {
		guard items.isEmpty else { return }
		DispatchQueue.global(qos: .userInteractive).async {
			for provider in itemProviders {
				let _ = provider.loadDataRepresentation(for: .image) { data, error in
					if let data, let image = UIImage(data: data), let thumbnail = image.preparingThumbnail(of: .init(width: size.width, height: 300)) {
						/// UI Must Be Updated On Main Thread
						DispatchQueue.main.async {
							items.append(.init(imageData: data, previewImage: thumbnail))
						}
					}
				}
			}
		}
	}
	
	/// Saving Items to SwiftData
	func saveItems() {
		
		Task{
			
			var idsToRemove: [String] = []
			for item in items{
				let path =  await ImageManager.storeImage(from: item.id, at: UIImage(data: item.imageData)!)
				if path != nil{
					idsToRemove.append(item.id)
				}
			}
			
			items.removeAll { item in
				idsToRemove.contains(item.id)
			}
			
			if items.count  == 0 {
				dismiss()
			}else{
				
			}
			
		}
		
		
	}
	
	/// Dismissing View
	func dismiss() {
		extensionContext?.completeRequest(returningItems: [])
	}
	
	private struct Item: Identifiable {
		var id: String = UUID().uuidString
		var imageData: Data
		var previewImage: UIImage
	}
}
