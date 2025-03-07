//
//  View+.swift
//  Meow
//
//  Created by He Cho on 2024/8/9.
//

import Foundation
import SwiftUI
import Combine


// MARK: - Line 视图

struct OutlineModifier: ViewModifier {
	@Environment(\.colorScheme) var colorScheme
	var cornerRadius: CGFloat = 20
	
	func body(content: Content) -> some View {
		content.overlay(
			RoundedRectangle(cornerRadius: cornerRadius)
				.stroke(
					.linearGradient(
						colors: [
							.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
							.black.opacity(0.1)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing)
				)
		)
	}
}
extension View{
	func addLine() -> some View {
		self.modifier(OutlineModifier())
	}
}



// MARK: - BackgroundColor2 视图

struct BackgroundColor2: ViewModifier {
	var opacity: Double = 0.6
	var cornerRadius: CGFloat = 20
	@Environment(\.colorScheme) var colorScheme
	
	func body(content: Content) -> some View {
		content
			.overlay(
				Color("dark_light")
					.opacity(colorScheme == .dark ? opacity : 0)
					.mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
					.blendMode(.overlay)
					.allowsHitTesting(false)
			)
	}
}

extension View {
	func backgroundColor(opacity: Double = 0.6) -> some View {
		self.modifier(BackgroundColor2(opacity: opacity))
	}
}
// MARK: - SlideFadeIn 视图

struct SlideFadeIn: ViewModifier {
	var show: Bool
	var offset: Double
	
	func body(content: Content) -> some View {
		content
			.opacity(show ? 1 : 0)
			.offset(y: show ? 0 : offset)
	}
}

extension View {
	func slideFadeIn(show: Bool, offset: Double = 10) -> some View {
		self.modifier(SlideFadeIn(show: show, offset: offset))
	}
}




// MARK: - BackgroundStyle 视图

struct OutlineOverlay: ViewModifier {
	@Environment(\.colorScheme) var colorScheme
	var cornerRadius: CGFloat = 20
	
	func body(content: Content) -> some View {
		content.overlay(
			RoundedRectangle(cornerRadius: cornerRadius)
				.stroke(
					.linearGradient(
						colors: [
							.white.opacity(colorScheme == .dark ? 0.6 : 0.3),
							.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
						],
						startPoint: .top,
						endPoint: .bottom)
				)
				.blendMode(.overlay)
		)
	}
}

struct BackgroundStyle: ViewModifier {
	var cornerRadius: CGFloat = 20
	var opacity: Double = 0.6
	@AppStorage("isLiteMode") var isLiteMode = true
	
	func body(content: Content) -> some View {
		content
			.backgroundColor(opacity: opacity)
			.cornerRadius(cornerRadius)
			.shadow(color: Color("Shadow").opacity(isLiteMode ? 0 : 0.3), radius: 20, x: 0, y: 10)
			.modifier(OutlineOverlay(cornerRadius: cornerRadius))
	}
}

extension View {
	func backgroundStyle(cornerRadius: CGFloat = 20, opacity: Double = 0.6) -> some View {
		self.modifier(BackgroundStyle(cornerRadius: cornerRadius, opacity: opacity))
	}
}



// MARK: - buttons 视图

struct ButtonPress: ViewModifier{
	
	var onPress:()->Void
	var onRelease:()->Void
	
	func body(content: Content) -> some View {
		content
			.simultaneousGesture(
				DragGesture(minimumDistance: 0)
					.onChanged({ _ in
						onPress()
					})
					.onEnded({ _ in
						onRelease()
					})
			)
	}
}


extension View{
	func pressEvents(onPress: @escaping(()->Void), onRelease: @escaping(()->Void))-> some View{
		modifier(ButtonPress(onPress: { onPress() }, onRelease: { onRelease() }))
	}
}


// MARK: - toolbarTips

struct TipsToolBarItemsModifier: ViewModifier {
	
	@State private var errorAnimate: Bool = true
	private let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
	var isConnected: Bool
	var isAuthorized: Bool
	let onAppearAction: () -> Void
	
	func body(content: Content) -> some View {
		content.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				if !isConnected || !isAuthorized {
					Button {
						onAppearAction()
					} label: {
						HStack{
							if !isConnected {
								signSymbol(icon1: "network", icon2: "network.slash")
							}
							
							if !isAuthorized {
								signSymbol(icon1: "bell", icon2: "bell.slash")
							}
						}
						.onReceive(timer){ _ in
							withAnimation(Animation.bouncy(duration: 0.5)) {
								errorAnimate.toggle()
							}
						}
					}
				}
			}
		}
	}
	
	@ViewBuilder
	private func signSymbol(icon1: String, icon2: String) -> some View{
		Image(systemName: errorAnimate ? icon1 : icon2)
			.symbolRenderingMode(.palette)
			.foregroundStyle(.red, .foreground)
	}
	
	
}

extension View{
	func tipsToolbar(wifi:Bool, notification:Bool , callback: @escaping () -> Void) -> some View{
		self.modifier(TipsToolBarItemsModifier(isConnected: wifi, isAuthorized: notification, onAppearAction: callback))
	}
}

// MARK: - TextFieldModifier

struct TextFieldModifier: ViewModifier {
	var icon: String
	var complete: (()-> Void)? = nil
	
	func body(content: Content) -> some View {
		content
			.overlay(
				HStack {
					Image(systemName: icon)
						.frame(width: 36, height: 36)
						.background(.ultraThinMaterial)
						.cornerRadius(14)
						.modifier(OutlineOverlay(cornerRadius: 14))
						.offset(x: -46)
						.accessibility(hidden: true)
						.symbolRenderingMode(.palette)
						.foregroundStyle(.tint,.secondary)
						.onTapGesture {
							complete?()
						}
					Spacer()
				}
			)
			.foregroundStyle(.primary)
			.padding(10)
			.padding(.leading, 43)
            .background(.ultraThinMaterial)
			.cornerRadius(20)
			.modifier(OutlineOverlay(cornerRadius: 20))
	}
}

extension View {
	func customField(icon: String, complete: (()-> Void)? = nil) -> some View {
		self.modifier(TextFieldModifier( icon: icon,complete: complete))
	}
}


// MARK: - LoadingPress


struct LoadingPress: ViewModifier{
	
	var show:Bool = false
	var title:String = ""
	
	func body(content: Content) -> some View {
		content
			.blur(radius: show ? 10 : 0)
			.disabled(show)
			.overlay {
				if show{
					VStack{
						
						ProgressView()
							.scaleEffect(3)
							.padding()
						
						Text(title)
							.font(.title3)
					}
					.toolbar(.hidden, for: .tabBar)
				}
			}
	}
}


extension View {
	func loading(_ show:Bool, _ title:String = "")-> some View{
		modifier(LoadingPress(show: show, title: title))
	}
}
 




extension View{
	@ViewBuilder
	func viewExtractor(result: @escaping (UIView)-> ()) -> some View{
		self
			.background(ViewExtractHelper(result: result))
			.compositingGroup()
	}
}

fileprivate struct ViewExtractHelper: UIViewRepresentable {
	var result:(UIView) -> ()
	func makeUIView(context: Context) -> some UIView {
		let view  = UIView(frame: .zero)
		view.backgroundColor = .clear
		view.isUserInteractionEnabled = false
		DispatchQueue.main.async {
			if let uikitview = view.superview?.superview?.subviews.last?.subviews.first{
				result(uikitview)
			}
		}
		
		return view
		
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) {
		
	}
}

extension View{
    @ViewBuilder
    func customPresentationCornerRadius(_ radius:CGFloat)-> some View{
        if #available(iOS 16.4, *){
            self
                .presentationCornerRadius(radius)
        }else {
            self
        }
    }
}







