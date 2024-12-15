//
//  File name:     ImagesView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/16.
	

import SwiftUI

@available(iOS 17.0, *)
struct ImageHomeView: View {
	@Environment(\.dismiss) var dismiss
	var coordinator: UICoordinator = .init()
	var body: some View {
		NavigationStack {
			@Bindable var bindableCoordinator = coordinator
			ScrollViewReader { reader in
				ScrollView(.vertical) {
					LazyVStack(alignment: .leading, spacing: 0) {

						LazyVGrid(columns: Array(repeating: GridItem(spacing: 3), count: 3), spacing: 3) {
							ForEach($bindableCoordinator.items) { $item in
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
					.environment(coordinator)
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
				.environment(coordinator)
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

					Text("Back")
				}
			})

			Spacer(minLength: 0)

			Button {

			} label: {
				Image(systemName: "ellipsis")
					.padding(10)
					.background(.bar, in: .circle)
			}
		}
		.padding([.top, .horizontal], 15)
		.padding(.bottom, 10)
//		.background(.ultraThinMaterial)
//		.offset(y: -100 * coordinator.dragProgress)
		.animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
	}
}

@available(iOS 17.0, *)
#Preview {
    ImageHomeView()
}
