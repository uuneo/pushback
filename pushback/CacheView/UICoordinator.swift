//
//  File name:     UICoordinator.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/17.
	

import SwiftUI


@available(iOS 17.0, *)
@Observable
class UICoordinator {
	var items: [imageItem] = sampleItems.compactMap({
		imageItem(title: $0.title, image: $0.image, previewImage: $0.image)
	})
	/// Animation Properties
	var selectedItem: imageItem?
	var animateView: Bool = false
	var showDetailView: Bool = false
	/// Scroll Positions
	var detailScrollPosition: String?
	var detailIndicatorPosition: String?
	/// Gesture Properties
	var offset: CGSize = .zero
	var dragProgress: CGFloat = 0

	func didDetailPageChanged() {
		if let updatedItem = items.first(where: { $0.id == detailScrollPosition }) {
			selectedItem = updatedItem
			/// Updating Indicator Position
			withAnimation(.easeInOut(duration: 0.1)) {
				detailIndicatorPosition = updatedItem.id
			}
		}
	}

	func didDetailIndicatorPageChanged() {
		if let updatedItem = items.first(where: { $0.id == detailIndicatorPosition }) {
			selectedItem = updatedItem
			/// Updating Detail Paging View As Well
			detailScrollPosition = updatedItem.id
		}
	}

	func toggleView(show: Bool) {
		if show {
			detailScrollPosition = selectedItem?.id
			detailIndicatorPosition = selectedItem?.id
			withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
				animateView = true
			} completion: {
				self.showDetailView = true
			}
		} else {
			showDetailView = false
			withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
				animateView = false
				offset = .zero
			} completion: {
				self.resetAnimationProperties()
			}
		}
	}

	func resetAnimationProperties() {
		selectedItem = nil
		detailScrollPosition = nil
		offset = .zero
		dragProgress = 0
		detailIndicatorPosition = nil
	}
}


