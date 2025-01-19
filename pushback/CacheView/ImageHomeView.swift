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
	@State private var isSelect:Bool = false
	@State private var selectImageArr:[ImageModel] = []
	@StateObject var coordinator: UICoordinator = .init()
	var body: some View {
		NavigationStack {
			ScrollViewReader { reader in
				ScrollView(.vertical) {
					LazyVStack(alignment: .leading, spacing: 0) {
						LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), spacing: 3) {
							ForEach($coordinator.items) { $item in
								GridImageView(item)
									.id(item.id)
									.didFrameChange { frame, bounds in
										let minY = frame.minY
										let maxY = frame.maxY
										let height = bounds.height

										if maxY < 0 || minY > height {
											item.appeared = false
										} else {
											item.appeared = true
										}
									}
									.onDisappear {
										item.appeared = false
									}
									.onTapGesture {
										coordinator.selectedItem = item
									}
							}
						}
						.padding(.vertical, 15)
					}
					.padding(.top, 50)
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
						   let preview = uiimage.preparingThumbnail(
							of: .init(
								width: max(uiimage.size.width / 5, 500),
								height: max(uiimage.size.height / 5, 500)
							)
						   ) {

							items.append(.init(title: image.another ?? image.url, image: uiimage, previewImage: preview))

						}
					}
					coordinator.items = items
				}
			}


		}
		.overlay(alignment: .top, content: {
			NavigationBar()
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
					.frame(width: size.width, height: size.height)
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
				HStack(spacing: 2) {
					Image(systemName: "chevron.left")
						.font(.title3)

					Text("设置")
				}
			})

			Spacer(minLength: 10)

			Text("图片缓存")

			Spacer(minLength: 10)

			Button {
				self.isSelect.toggle()
			} label: {
				Text( isSelect  ? String(localized: "取消") : String(localized: "选择"))
			}
		}
		.padding([.top, .horizontal], 15)
		.padding(.bottom, 10)
		.background(.ultraThinMaterial)
		.offset(y: coordinator.selectedItem != nil ? -120 : 0)
		.animation(.easeInOut(duration: 0.15), value: coordinator.selectedItem)
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
