//
//  File name:     ImagesView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/16.
	

import SwiftUI
import Defaults

@available(iOS 17.0, *)
struct ImageHomeView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject var coordinator = UICoordinator.shared
	@Default(.photoName) var photoName
	var showClose:Bool = false
	var body: some View {
		NavigationStack {
			ScrollViewReader { reader in
				ScrollView(.vertical) {
					LazyVStack(alignment: .leading, spacing: 0) {
						LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: ISPAD ? 6 : 3), spacing: 3) {
							ForEach(coordinator.items, id: \.id) { item in
								GridImageView(item)
									.id(item.id)
									.didFrameChange { frame, bounds in
										let minY = frame.minY
										let maxY = frame.maxY
										let height = bounds.height

										if let index = coordinator.items.firstIndex(where: {$0.id == item.id}){
											if maxY < 0 || minY > height {
												coordinator.items[index].appeared = false
											} else {
												coordinator.items[index].appeared = true
											}

										}

									}
									.onDisappear {
										if let index = coordinator.items.firstIndex(where: {$0.id == item.id}){
											coordinator.items[index].appeared = false
										}

									}
									.overlay(alignment: .bottomTrailing){
										Image(systemName: "checkmark.circle")
											.resizable()
											.frame(width: 35, height: 35, alignment: .center)
											.symbolRenderingMode(.palette)
											.foregroundStyle(.tint, .white)
											.opacity(coordinator.selectItems.contains(where: {$0.id == item.id}) ? 1 : 0)
									}
									.onTapGesture {
										if coordinator.isEditMode{
											coordinator.addOrDelItem(item: item)
										}else{
											coordinator.selectedItem = item
										}

									}

							}
						}
						.padding(.vertical, 15)
						.onAppear{
							coordinator.selectItems = []
						}
					}
					.padding(.top, 50)
					.padding(.bottom, coordinator.isEditMode ? 60 : 0)
				}
				.onChange(of: coordinator.selectedItem) { oldValue, newValue in
					if let item = coordinator.items.first(where: { $0.id == newValue?.id }), !item.appeared {
						/// Scroll to this item, as this is not visible on the screen
						reader.scrollTo(item.id, anchor: .bottom)
					}
				}
			}
			.toolbar(.hidden, for: .navigationBar, .tabBar)
			.task {

				for await imagesArr in Defaults.updates(.images) {

					var items:[imageItem] = []
					for image in imagesArr {
						if let imageUrl = await ImageManager.downloadImage(image.url),
						   let uiimage = UIImage(contentsOfFile: imageUrl),
						   let preview = uiimage.preparingThumbnail( of: .init( width: max(uiimage.size.width / 5, 500), height: max(uiimage.size.height / 5, 500))) {

							items.append(.init(id: image.id, title:  image.another ?? image.url, url: image.url, another: image.another, sha256: image.sha256, image: uiimage, previewImage: preview))

						}
					}
					coordinator.items = items

				}
			}

		}
		.overlay(alignment: .center){
			if Defaults[.images].count == 0{
				Text("啥都没有")
					.font(.title)
					.foregroundStyle(.gray)
			}
		}
		.overlay(alignment: .top, content: {
			NavigationBar()
		})
		.overlay(alignment: .bottom, content: {
			BottomBar()
		})
		.overlay {
			Rectangle()
				.fill(.background)
				.ignoresSafeArea()
				.opacity(coordinator.animateView ? 1 - coordinator.dragProgress : 0)
		}
		.overlay {
			if coordinator.selectedItem != nil {
				ImagePreview()
					.environmentObject(coordinator)
					.allowsHitTesting(coordinator.showDetailView)
			}
		}
		.overlayPreferenceValue(ImageHeroKey.self) { value in
			if let selectedItem = coordinator.selectedItem,
			   let sAnchor = value[selectedItem.id + "SOURCE"],
			   let dAnchor = value[selectedItem.id + "DEST"] {
				ImageHeroLayer(
					item: selectedItem,
					sAnchor: sAnchor,
					dAnchor: dAnchor
				)
				.environmentObject(coordinator)
			}
		}
	}


	func deleteimage(){


		coordinator.items = coordinator.items.filter({!coordinator.selectItems.contains( $0 )})

		for image in  coordinator.selectItems{
			ImageManager.deleteImage(image.url)
		}


		let delImageUrls = coordinator.selectItems.compactMap({return $0.url})

		Defaults[.images].removeAll { res in
			delImageUrls.contains { item in
				res.url == item
			}
		}
		coordinator.selectItems = []

		Toast.shared.present(title: String(localized: "删除成功"), symbol: "photo.badge.checkmark")
	}

	/// Image View For Grid
	@ViewBuilder
	func GridImageView(_ item: imageItem) -> some View {
		GeometryReader {
			let size = $0.size

			Rectangle()
				.fill(.clear)
				.anchorPreference(key: ImageHeroKey.self, value: .bounds, transform: { anchor in
					return [item.id + "SOURCE": anchor]
				})

			if let previewImage = item.previewImage {
				Image(uiImage: previewImage)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: size.width, height: size.width)
					.clipped()
					.opacity(coordinator.selectedItem?.id == item.id ? 0 : 1)

			}
		}
		.frame(height: 130)
		.contentShape(.rect)
	}

	/// Custom Navigation Bar
	@ViewBuilder
	func NavigationBar() -> some View {
		HStack {

			Button(action: { dismiss() }, label: {
				if showClose{
					Image(systemName: "xmark.seal")
						.resizable()
						.scaledToFit()
						.frame(width: 30)
						.padding(5)
						.contentShape(Circle())
				}else{

					HStack(spacing: 2) {
						Image(systemName: "chevron.left")
							.font(.title3)

						Text("图片缓存")
					}
				}

			})



			Spacer(minLength: 10)
			if coordinator.isEditMode{
				Button{

					if coordinator.selectItems.count == coordinator.items.count{
						coordinator.selectItems = []
					}else{
						coordinator.selectItems = coordinator.items
					}
				}label: {
					Text(coordinator.selectItems.count == coordinator.items.count ?  "取消全选" : "全选")
						.foregroundStyle(coordinator.selectItems.count == coordinator.items.count ? .red : .green)
						.padding(.horizontal)
				}
			}
			Button{
				coordinator.isEditMode = !coordinator.isEditMode
				if !coordinator.isEditMode{
					coordinator.selectItems = []
				}
			}label: {
				Text(coordinator.isEditMode ?  "取消" : "选择")
					.padding(.horizontal)
			}.disabled(Defaults[.images].count == 0)

		}
		.padding(.top)
		.padding(.horizontal, 15)
		.padding(.bottom, 10)
		.offset(y: coordinator.selectedItem != nil ? -120 : 0)
		.animation(.easeInOut(duration: 0.15), value: coordinator.selectedItem)
	}


	@ViewBuilder
	func BottomBar() -> some View{
		HStack{



			Text( coordinator.selectItems.count == 0 ? String(localized: "选择图片") : String(format: String(localized:  "已选择%d张图片"), coordinator.selectItems.count))
				.animation(.snappy, value: coordinator.selectItems.count)

			Spacer()

			let imagesData = coordinator.selectItems.compactMap({ Image(uiImage: $0.image!)})

			ShareLink(items: imagesData, subject: Text( "图片"), message: Text( "图片")) { value in
				SharePreview( String(format: String(localized:  "%d张图片"), imagesData.count) , image: value)
			} label: {
				Image(systemName:  "square.and.arrow.up")
					.resizable()
					.scaledToFit()
					.frame(width: 20)
			}.disabled(coordinator.selectItems.count == 0 || coordinator.items.count == 0)


		}
		.padding()
		.background(.ultraThinMaterial)
		.offset(y: coordinator.isEditMode ? 0 : 200)
		.animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
	}
}

@available(iOS 17.0, *)
#Preview {
    ImageHomeView()
}


extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
	override open func viewDidLoad() {
		super.viewDidLoad()
		interactivePopGestureRecognizer?.delegate = self
	}
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		return viewControllers.count > 1
	}
}

