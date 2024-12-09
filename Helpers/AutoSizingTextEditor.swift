//
//  AutoSizeEditView.swift
//  pushback
//
//  Created by He Cho on 2024/11/2.
//
import SwiftUI

struct AutoSizingTextEditor: UIViewRepresentable {
	@Binding var text: String
	var minHeight: CGFloat
	var maxHeight: CGFloat

	func makeUIView(context: Context) -> UITextView {
		let textView = UITextView()
		textView.isScrollEnabled = false
		textView.backgroundColor = .clear
		textView.font = UIFont.systemFont(ofSize: 16)
		textView.delegate = context.coordinator
		return textView
	}
	
	func updateUIView(_ uiView: UITextView, context: Context) {
		uiView.text = text
		uiView.sizeToFit()
		let size = uiView.sizeThatFits(CGSize(width: uiView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		
		// 更新高度限制
		if size.height < minHeight {
			uiView.heightAnchor.constraint(equalToConstant: minHeight).isActive = true
		} else if size.height > maxHeight {
			uiView.isScrollEnabled = true
			uiView.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
		} else {
			uiView.isScrollEnabled = false
			uiView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, UITextViewDelegate {
		var parent: AutoSizingTextEditor

		init(_ parent: AutoSizingTextEditor) {
			self.parent = parent
		}

		func textViewDidChange(_ textView: UITextView) {
			DispatchQueue.main.async {
				self.parent.text = textView.text
			}
		}
	}
}
