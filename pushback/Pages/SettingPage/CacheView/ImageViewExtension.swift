//
//  File name:     ImageViewExtension.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/17.
import SwiftUI

@available(iOS 17.0, *)
extension View {
	@ViewBuilder
	func didFrameChange(result: @escaping (CGRect, CGRect) -> ()) -> some View {
		self
			.overlay {
				GeometryReader {
					let frame = $0.frame(in: .scrollView(axis: .vertical))
					let bounds = $0.bounds(of: .scrollView(axis: .vertical)) ?? .zero

					Color.clear
						.preference(key: FrameKey.self, value: .init(frame: frame, bounds: bounds))
						.onPreferenceChange(FrameKey.self, perform: { value in
							result(value.frame, value.bounds)
						})
				}
			}
	}
}



struct ViewFrame: Equatable {
	var frame: CGRect = .zero
	var bounds: CGRect = .zero
}

struct FrameKey: PreferenceKey {
	static var defaultValue: ViewFrame = .init()
	static func reduce(value: inout ViewFrame, nextValue: () -> ViewFrame) {
		value = nextValue()
	}
}
