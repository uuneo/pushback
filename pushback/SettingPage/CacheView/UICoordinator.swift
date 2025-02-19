//
//  File name:     UICoordinator.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/17.
	

import SwiftUI
import Defaults


@available(iOS 17.0, *)
class UICoordinator: ObservableObject  {

	static let shared = UICoordinator()

	private init(){}

	@Published var items: [imageItem] = []
	@Published var selectedItem: imageItem?
	@Published var animateView: Bool = false
	@Published var showDetailView: Bool = false
	@Published var detailScrollPosition: String?
	@Published var detailIndicatorPosition: String?
	@Published var offset: CGSize = .zero
	@Published var dragProgress: CGFloat = 0
	@Published var selectItems:[imageItem] = []
	@Published var isEditMode:Bool = false


	func isSelect(item: imageItem) -> Bool{
		return selectItems.contains(where: {item.id == $0.id})
	}

	func addOrDelItem(item: imageItem){
		if isSelect(item: item){
			selectItems = selectItems.filter({$0.id != item.id})
		}else{
			selectItems.append(item)
		}
	}

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


