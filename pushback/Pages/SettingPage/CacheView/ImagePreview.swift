//
//  File name:     ImagePreview.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/16.
	

import SwiftUI

@available(iOS 17.0, *)
struct ImagePreview: View {
	@EnvironmentObject private var coordinator:UICoordinator
	@State private var showLocalView:Bool = false
	var body: some View {
		VStack(spacing: 0) {
			NavigationBar()

			GeometryReader {
				let size = $0.size

				ScrollView(.horizontal) {
					LazyHStack(spacing: 0) {
						ForEach(coordinator.items) { item in
							/// Image View
							ImageView(item, size: size)
						}
					}
					.scrollTargetLayout()
				}
				/// Making it as a Paging View
				.scrollTargetBehavior(.paging)
				.scrollIndicators(.hidden)
				.scrollPosition(id: .init(get: {
					return coordinator.detailScrollPosition
				}, set: {
					coordinator.detailScrollPosition = $0
				}))
				.onChange(of: coordinator.detailScrollPosition, { oldValue, newValue in
					coordinator.didDetailPageChanged()
				})
				.background {
					if let selectedItem = coordinator.selectedItem {
						Rectangle()
							.fill(.clear)
							.anchorPreference(key: ImageHeroKey.self, value: .bounds, transform: { anchor in
								return [selectedItem.id + "DEST": anchor]
							})
					}
				}
				.offset(coordinator.offset)

				Rectangle()
					.foregroundStyle(.clear)
					.frame(width: 30)
					.contentShape(.rect)
					.gesture(
						DragGesture(minimumDistance: 0)
							.onChanged { value in
								let translation = value.translation
								coordinator.offset = translation
								/// Progress For Fading Out the Detail View
								let heightProgress = max(min(translation.height / 200, 1), 0)
								coordinator.dragProgress = heightProgress
							}.onEnded { value in
								let translation = value.translation
								let velocity = value.velocity
								//let width = translation.width + (velocity.width / 5)
								let height = translation.height + (velocity.height / 5)

								if height > (size.height * 0.5) {
									/// Close View
									coordinator.toggleView(show: false)
								} else {
									/// Reset to Origin
									withAnimation(.easeInOut(duration: 0.2)) {
										coordinator.offset = .zero
										coordinator.dragProgress = 0
									}
								}
							}
					)
			}
			.opacity(coordinator.showDetailView ? 1 : 0)

			BottomIndicatorView()
				.offset(y: coordinator.showDetailView ? (120 * coordinator.dragProgress) : 120)
				.animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
		}
		.onAppear {
			coordinator.toggleView(show: true)
		}
		.sheet(isPresented: $showLocalView) {
			if let imageItem = coordinator.selectedItem, let image = Defaults[.images].first(where: {$0.url == imageItem.url}) {
				ChangeKeyImageKey(image: image)
			}else{
				Spacer()
					.onAppear{
						self.showLocalView.toggle()
					}
			}
		}
	}

	/// Custom Navigation Bar
	@ViewBuilder
	func NavigationBar() -> some View {
		HStack {
			Button(action: { coordinator.toggleView(show: false) }, label: {
				HStack(spacing: 2) {
					Image(systemName: "chevron.left")
						.font(.title3)

					Text("关闭")
				}
			})

			Spacer(minLength: 0)

			Button{
				self.showLocalView.toggle()
			}label:{
				Image(systemName: "signature")
					.resizable()
					.scaledToFit()
					.frame(width: 25)
					.padding(5)
					.background(.bar, in: .circle)
					.padding(.horizontal, 10)
			}.tint(.green)

			Button{
				if let image = coordinator.selectedItem{
					ImageManager.deleteImage(image.url)
					Toast.shared.present(title: String(localized: "清除缓存成功!"), symbol: .success)
					if Defaults[.images].count == 0{
						coordinator.toggleView(show: false)
					}

				}
			}label:{
				Image(systemName: "arrow.up.trash")
					.resizable()
					.scaledToFit()
					.frame(width: 20)
					.padding(5)
					.background(.bar, in: .circle)
					.padding(.horizontal,10)
			}.tint(.red)


		}
		.padding()
		.background(.ultraThinMaterial)
		.offset(y: coordinator.showDetailView ? (-120 * coordinator.dragProgress) : -120)
		.animation(.easeInOut(duration: 0.15), value: coordinator.showDetailView)
	}

	@ViewBuilder
	func ImageView(_ item: imageItem, size: CGSize) -> some View {
		if let image = item.image {
			Image(uiImage: image)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: size.width, height: size.height)
				.clipped() 
				.contentShape(.rect)
		}
	}

	/// Bottom Indicator View
	@ViewBuilder
	func BottomIndicatorView() -> some View {
		GeometryReader {
			let size = $0.size

			ScrollView(.horizontal) {
				LazyHStack(spacing: 5) {
					ForEach(coordinator.items) { item in
						/// Preview Image View
						if let image = item.previewImage {
							Image(uiImage: image)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 50, height: 50)
								.clipShape(.rect(cornerRadius: 10))
								.scaleEffect(0.97)

						}
					}
				}
				.padding(.vertical, 10)
				.scrollTargetLayout()
			}
			/// 50 - Item Size Inside ScrollView
			.safeAreaPadding(.horizontal, (size.width - 50) / 2)
			.overlay {
				/// Active Indicator Icon
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color.gray, lineWidth: 2)
					.frame(width: 50, height: 50)
					.allowsHitTesting(false)
			}
			.scrollTargetBehavior(.viewAligned)
			.scrollPosition(id: .init(get: {
				return coordinator.detailIndicatorPosition
			}, set: {
				coordinator.detailIndicatorPosition = $0
			}))
			.scrollIndicators(.hidden)
			.onChange(of: coordinator.detailIndicatorPosition) { oldValue, newValue in
				coordinator.didDetailIndicatorPageChanged()
			}
		}
		.frame(height: 70)
		.background {
			Rectangle()
				.fill(.ultraThinMaterial)
				.ignoresSafeArea()
		}
	}
}

@available(iOS 17.0, *)
#Preview {

    ImagePreview()
}
