//
//  ParallaxImageView.swift
//  Meow
//
//  Created by uuneo 2024/10/6.
//
import SwiftUI

///  ParallaxImageView(maximumMovement: 150, usesFullWidth: true) { size in
///  				Image(.pic2)
///						.resizable()
///						.aspectRatio(contentMode: .fill)
///						.frame(width: size.width, height: size.height)
///					}
///						.frame(height: 400)
///	视差滚动
@available(iOS 17.0, *)
struct ParallaxImageView<Content: View>: View {
	var maximumMovement: CGFloat = 100
	var usesFullWidth: Bool = false
	@ViewBuilder var content: (CGSize) -> Content
	var body: some View {
		GeometryReader {
			let size = $0.size
			/// Movement Animation Properties
			let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
			let scrollViewHeight = $0.bounds(of: .scrollView)?.size.height ?? 0
			let maximumMovement = min(maximumMovement, (size.height * 0.4))
			let stretchedSize: CGSize = .init(width: size.width, height: size.height + maximumMovement)
			
			let progress = minY / scrollViewHeight
			let cappedProgress = max(min(progress, 1.0), -1.0)
			let movementOffset = cappedProgress * -maximumMovement
			
			content(stretchedSize)
				.offset(y: movementOffset)
				.frame(width: stretchedSize.width, height: stretchedSize.height)
				.frame(width: size.width, height: size.height)
				.clipped()
		}
		.containerRelativeFrame(usesFullWidth ? [.horizontal] : [])
	}
}
