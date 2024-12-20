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


	private func open(url: URL) {
		var responder: UIResponder? = self as UIResponder
		let selector = #selector(openURL(_:))

		while responder != nil {
			if responder!.responds(to: selector) && responder != self {
				responder!.perform(selector, with: url)

				return
			}

			responder = responder?.next
		}
	}

	@objc
	private func openURL(_ url: URL) {
		return
	}

}

fileprivate struct ShareView: View {
	var itemProviders: [NSItemProvider]
	var extensionContext: NSExtensionContext?
	var error:String?
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
				if items.filter({$0.name.count == 0}).count != 0{
					Text( "必须输入图片key")
						.foregroundStyle(.red)
						.transition(.slide)
				}

				ScrollView(.horizontal) {
					LazyHStack(spacing: 0) {
						ForEach(items, id: \.id) { item in
							VStack{
								Image(uiImage: item.previewImage)
									.resizable()
									.aspectRatio(contentMode: .fit)
									.padding(.horizontal, 15)
									.frame(width: size.width)
								
								TextField( "输入图片Key", text: Binding(get: { item.name }, set: { value in
									if let index = items.firstIndex(where: {$0.id == item.id}){
										items[index].name = value
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
				Button{
					if items.filter({$0.name.count == 0}).count == 0{
						saveItems()
					}
				}label: {
					Text( "保存")
						.font(.title3)
						.fontWeight(.semibold)
						.padding(.vertical, 10)
						.frame(maxWidth: .infinity)
						.foregroundStyle(.white)
						.background(.blue, in: .rect(cornerRadius: 10))
						.contentShape(.rect)
				}
				
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
					if let data,
					   let image = UIImage(data: data),
					   let thumbnail = image.preparingThumbnail(of: .init(width: size.width, height: 300)) {
						/// UI Must Be Updated On Main Thread
						DispatchQueue.main.async {
							items.append(.init(name: "", imageData: data, previewImage: thumbnail))
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
				await ImageManager.storeImage(data: item.imageData, key: item.name, expiration: .never) { success in
					if success {
						idsToRemove.append(item.id)
					}
				}

			}
			
			items.removeAll { item in
				idsToRemove.contains(item.id)
			}
			
			if items.count  == 0 {
				dismiss()
			}
		}
		
		
	}

	/// Dismissing View
	func dismiss() {
		extensionContext?.completeRequest(returningItems: [])
	}
	
	private struct Item: Identifiable {
		var id: String = UUID().uuidString
		var name:String
		var imageData: Data
		var previewImage: UIImage
	}






}
