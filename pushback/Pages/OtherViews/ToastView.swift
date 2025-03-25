//
//  ToastView.swift
//  pushback
//
//  Created by uuneo 2024/10/10.
//
///
///  Button("Present Toast") {
///			Toast.shared.present	(
///				title: "AirPods Pro",
///				symbol: "airpodspro",
///				timing: .short
///			)
///		}

import SwiftUI

/// Root View for Creating Overlay Window
struct RootView<Content: View>: View {
	@ViewBuilder var content: Content
	/// View Properties
	@State private var overlayWindow: UIWindow?
	var body: some View {
		content
			.onAppear {
				if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
					let window = PassthroughWindow(windowScene: windowScene)
					window.backgroundColor = .clear
					/// View Controller
					let rootController = UIHostingController(rootView: ToastGroup())
					rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
					rootController.view.backgroundColor = .clear
					window.rootViewController = rootController
					window.isHidden = false
					window.isUserInteractionEnabled = true
					window.tag = 1009
					
					overlayWindow = window
				}
			}
	}
}



fileprivate class PassthroughWindow: UIWindow {
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		guard let hitView = super.hitTest(point, with: event),
				let rootView = rootViewController?.view
		else { return nil }
		
		if #available(iOS 18, *) {
			for subview in rootView.subviews.reversed() {
				/// Finding if any of rootview's is receving hit test
				let pointInSubView = subview.convert(point, from: rootView)
				if subview.hitTest(pointInSubView, with: event) != nil {
					return hitView
				}
			}
			
			return nil
		} else {
			return hitView == rootView ? nil : hitView
		}
	}
}


class Toast: ObservableObject {
	static let shared = Toast()
	private init() { }
	@Published fileprivate var toasts: [ToastItem] = []
	
	
	
	func present(title: String, symbol: String?, tint: Color = .primary,isUserInteractionEnabled:Bool = true, timing: ToastTime = .medium) {
		DispatchQueue.main.async{
			withAnimation(.snappy) {
				self.toasts.append(
					.init(
						title: title,
						symbol: symbol,
						tint: tint,
						isUserInteractionEnabled: true,
						timing: timing
					)
				)
			}
		}
	}
	
	func present(title: String, symbol: ToastSymbol?, tint: Color = .primary,isUserInteractionEnabled:Bool = true ,timing: ToastTime = .medium) {
		
		DispatchQueue.main.async{
			withAnimation(.snappy) {
				self.toasts.append(
					.init(
						title: title,
						symbol: symbol?.rawValue,
						tint: symbol != nil ? symbol!.color  : tint,
						isUserInteractionEnabled: isUserInteractionEnabled,
						timing: timing
					)
				)
			}
		}
		
	
	}
}

fileprivate struct ToastItem: Identifiable {
	let id: UUID = .init()
	/// Custom Properties
	var title: String
	var symbol: String?
	var tint: Color
	var isUserInteractionEnabled: Bool
	/// Timing
	var timing: ToastTime = .medium
}

enum ToastTime: CGFloat {
	case short = 1.0
	case medium = 3.0
	case long = 5.0
}

enum ToastSymbol: String{
	case success = "checkmark.bubble"
	case info = "info.bubble"
	case question = "questionmark.circle"
	case error = "xmark.app"
	case copy = "doc.on.doc"
	
	var color:Color{
		switch self {
		case .success: .green
		case .info: .orange
		case .question: .pink
		case .error: .gray
		case .copy: .green
		}
	}
}


fileprivate struct ToastGroup: View {
	@ObservedObject var model = Toast.shared
	var body: some View {
		GeometryReader {
			let size = $0.size
			let safeArea = $0.safeAreaInsets
			
			ZStack {
				ForEach(model.toasts) { toast in
					ToastView(size: size, item: toast)
						.scaleEffect(scale(toast))
						.offset(y: offsetY(toast))
						.zIndex(Double(model.toasts.firstIndex(where: { $0.id == toast.id }) ?? 0))
				}
			}
			
			
			
			.padding(.bottom, safeArea.top == .zero ? 15 : 10)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
		}
	}
	
	func offsetY(_ item: ToastItem) -> CGFloat {
		let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
		let totalCount = CGFloat(model.toasts.count) - 1
		return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
	}
	
	func scale(_ item: ToastItem) -> CGFloat {
		let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
		let totalCount = CGFloat(model.toasts.count) - 1
		return 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
	}
}

fileprivate struct ToastView: View {
	var size: CGSize
	var item: ToastItem
	/// View Properties
	@State private var delayTask: DispatchWorkItem?
	var body: some View {
		HStack(spacing: 0) {
			if let symbol = item.symbol {
				Image(systemName: symbol)
					.font(.title3)
					.padding(.trailing, 10)
			}
			
			Text(item.title)
		}
		.foregroundStyle(item.tint)
		.padding(.horizontal, 15)
		.padding(.vertical, 8)
		.background(
			.background
				.shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
				.shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
		   in: .capsule
				
		)
		.contentShape(.capsule)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded({ value in
                    guard item.isUserInteractionEnabled else { return }
                    let endX = value.translation.width
                    
                    
                    if abs(endX) > 30 {
                        /// Removing Toast
                        removeToast()
                    }
                })
        )
		.onAppear {
			guard delayTask == nil else { return }
			delayTask = .init(block: {
				removeToast()
			})
			
			if let delayTask {
				DispatchQueue.main.asyncAfter(deadline: .now() + item.timing.rawValue, execute: delayTask)
			}
		}
		/// Limiting Size
		.frame(maxWidth: size.width * 0.7)
		.transition(.offset(y: 150))
	
	}
	
	func removeToast() {
		if let delayTask {
			delayTask.cancel()
		}
		
		withAnimation(.snappy) {
			Toast.shared.toasts.removeAll(where: { $0.id == item.id })
		}
	}
}

