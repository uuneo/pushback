//
//  File name:     SlideLineView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/13.
	

import SwiftUI


struct SlideLineView<T: CaseIterable, M: View>: View where T: Hashable {
	@Binding var data: T

	var totalNum: Int = 4
	var vline: CGSize = .init(width: 4, height: 10)
	@ViewBuilder var label: () -> M
	private let allCases: [T]

	private var lineNumber: Int {
		max(2, totalNum - 1)
	}

	init(data: Binding<T>, totalNum: Int = 4, vline: CGSize = .init(width: 4, height: 10),label: @escaping () -> M) {
		self._data = data
		self.totalNum = totalNum
		self.vline = vline
		self.allCases = Array(T.allCases)
		self.label = label
	}

	private var selectedIndex: Int {
		guard let index = allCases.firstIndex(of: data) else { return 0 }
		return index
	}

	private func setSelect(_ index: Int) {
		guard index >= 0 && index < allCases.count else { return }
		if data != allCases[index] {
			data = allCases[index]
			Task{
				let generator = UIImpactFeedbackGenerator(style: .heavy)
				generator.impactOccurred()
			}
		}

	}

	var body: some View {
		GeometryReader { proxy in
			let width = proxy.size.width
			let viewWidth = width / CGFloat(lineNumber)
			let offset: CGFloat = min(CGFloat(selectedIndex) * viewWidth - 10, width)

			VStack{
				label()
				ZStack(alignment: .leading) {
					// Static Line and Steps
					HStack(spacing: 0) {
						Capsule()
							.fill(Color.blue)
							.frame(width: vline.width, height: vline.height)
							.contentShape(Rectangle())
							.onTapGesture {
								setSelect(0)
							}
						ForEach(0..<lineNumber, id: \.self) { index in
							Group {
								Rectangle()
									.fill(selectedIndex > index ? Color.blue : .gray)
									.frame(height: vline.width)
									.contentShape(Rectangle())
									.onTapGesture {
										setSelect(max(0, index))
									}

								Rectangle()
									.fill(selectedIndex > index ? Color.blue : .gray)
									.frame(height: vline.width)
									.contentShape(Rectangle())
									.onTapGesture {
										setSelect(index + 1)
									}

								Capsule()
									.fill(selectedIndex > index ? Color.blue : .gray)
									.frame(width: vline.width, height: vline.height)
									.contentShape(Rectangle())
									.onTapGesture {
										setSelect(index + 1)
									}
							}
						}
					}
					.frame(height: proxy.size.height / 2)
					.animation(.bouncy,value: selectedIndex)
					// Movable Circle
					Circle()
						.fill(Color("dark_light"))
						.frame(width: vline.height * 2, height: vline.height * 2)
						.background(Circle().stroke(Color.blue, lineWidth: 8))
						.offset(x: offset)
						.gesture(DragGesture().onChanged { value in
							let newIndex = Int((value.location.x + viewWidth / 2) / viewWidth)
							setSelect(min(lineNumber, newIndex))
						})
				}
			}

		}
	}
}







#Preview {
    MoreOperationsView()
	
}
