//
//  View+.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
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
    var maxX:Double = 10
	var onPress:((DragGesture.Value)->Void)? = nil
	var onRelease:((DragGesture.Value)->Bool)? = nil
    
    @State private var ispress = false
    
	func body(content: Content) -> some View {
		content
            .contentShape(Rectangle())
            .scaleEffect(ispress ? 0.99 : 1)
            .opacity(ispress ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.1), value: ispress)
			.simultaneousGesture(
				DragGesture(minimumDistance: 0)
					.onChanged({ result in
                        self.ispress = true
						onPress?(result)
					})
					.onEnded({ result in
                        self.ispress = false
                        if abs(result.translation.width) <= maxX {
                            
                            if let success = onRelease?(result), success{
                                vibration()
                            }
                        }
					})
			)
	}
    
    func vibration(){
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}


extension View{
    func pressEvents(_ maxX:Double = 0.0, onPress: ((DragGesture.Value)->Void)? = nil, onRelease: ((DragGesture.Value)->Bool)? = nil)-> some View{
        modifier(ButtonPress(maxX: maxX, onPress:onPress, onRelease: onRelease))
	}
    
    func button(_ maxX:Double = 0.0, onPress: ((DragGesture.Value)->Void)? = nil, onEnd: ((DragGesture.Value)->Bool)? = nil)-> some View{
        modifier(ButtonPress(maxX: maxX, onPress:onPress, onRelease: onEnd))
    }
}


struct replaceSymbol: ViewModifier{
    var icon1:String
    var icon2:String
    var delay:Double = 1
    private let timer = Timer.publish(every: 1.0, on: .current, in: .common).autoconnect()
    @State private var errorAnimate: Bool = true
    
    func body(content: Content) -> some View {
        Image(systemName: errorAnimate ? icon1 : icon2)
            .symbolEffect(.replace, delay: delay)
            .onReceive(timer){ _ in
                withAnimation(Animation.bouncy(duration: 0.5)) {
                    errorAnimate.toggle()
                }
            }
        
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
						.frame(width: 30, height: 30)
						.background(.ultraThinMaterial)
						.cornerRadius(8)
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
			.padding()
			.padding(.leading, 43)
            .background(.ultraThinMaterial)
			.cornerRadius(20)
			.modifier(OutlineOverlay(cornerRadius: 20))
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
    func customField(icon: String, complete: (()-> Void)? = nil) -> some View {
        self.modifier(TextFieldModifier( icon: icon,complete: complete))
    }
    
	func loading(_ show:Bool, _ title:String = "")-> some View{
		modifier(LoadingPress(show: show, title: title))
	}
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


extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    /// https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    
    @ViewBuilder func `if` <Content: View>(_ condition: Bool, transform: () -> Content) -> some View {
        if condition {
            transform()
        } else {
            self
        }
    }
}

struct GradientForegroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                colors: [Color(hex: "4285f4"), Color(hex: "9b72cb"), Color(hex: "d96570"), Color(hex: "#d96570")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct MovingGradientForegroundStyle: ViewModifier {
    @State private var animateGradient = false

    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(
                colors: [Color(hex: "4285f4"), Color(hex: "9b72cb")],
                startPoint: animateGradient ? .leading : .trailing,
                endPoint: animateGradient ? .trailing : .leading
            )
            .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: animateGradient)
        )
        .mask(content)
        .onAppear {
            animateGradient = true
        }
    }
}


// 扩展 CornerRadius 以支持特定角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// 自定义 RoundedCorner 形状
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

enum sybolEffectType{
   
    /// 跳动
    case pulse
    /// 弹跳
    case bounce
    /// 旋转
    case rotate
    /// 呼吸
    case breathe
    /// 缩放
    case scale
    /// 可变颜色
    case variableColor
    /// 替换
    case replace
    
    case wiggle
    
    case replaceblack
        
}

enum RepeatBehaviorType{
    case continuous
    case delay
}

extension View{
    @ViewBuilder func symbolEffect(_ type:sybolEffectType = .bounce, delay: Double? = nil) -> some View {
        
        
        if #available(iOS 18.0, *) {
           
            
            var repeatBehavior1:SymbolEffectOptions.RepeatBehavior{
                if delay == nil{
                    return .continuous
                }else {
                    return .periodic(delay: delay == 0 ? Double(Int.random(in: 1...10)) : delay)
                }
            }
            
            Group{
                switch type {
                case .pulse:
                    self.symbolEffect(.pulse.byLayer, options: .repeat(repeatBehavior1))
                case .bounce:
                    self.symbolEffect(.bounce.down.byLayer, options: .repeat(repeatBehavior1))
                case .rotate:
                    self.symbolEffect(.rotate.clockwise.byLayer, options: .repeat(repeatBehavior1))
                case .breathe:
                    self.symbolEffect(.breathe.pulse.byLayer, options: .repeat(repeatBehavior1))
                case .scale:
                    self.symbolEffect(.scale.up.byLayer, options: .repeat(repeatBehavior1))
                case .variableColor:
                    self.symbolEffect(.variableColor.cumulative.dimInactiveLayers.nonReversing, options: .repeat(repeatBehavior1))
                case .wiggle:
                    self.symbolEffect(.wiggle.clockwise.byLayer, options: .repeat(repeatBehavior1))
                case .replace:
                    self.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .repeat(repeatBehavior1)))
                case .replaceblack:
                    self.contentTransition(.symbolEffect(.replace))
                
                }
            
            }
            
        } else {
            self
        }
        
    }
}


struct ListButton<LEFT:View, Trailing: View>:View {
    @ViewBuilder var leading:() -> LEFT
    @ViewBuilder var trailing: () -> Trailing
    var action:() -> Bool
    var showRight:Bool
    
    init(
           @ViewBuilder leading: @escaping () -> LEFT,
           @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
           showRight:Bool = true,
           action: @escaping () -> Bool
       ) {
           self.leading = leading
           self.trailing = trailing
           self.action = action
           self.showRight = showRight
       }
    
    
    var body: some View {
        HStack{
            leading()
            Spacer()
            trailing()
            if showRight{
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
        }.pressEvents(onRelease:{_ in
            return action()
        })
    }
}

struct CustomRoundedRectangle: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // 限制不要超过矩形大小的一半
        let tl = min(min(topLeft, h/2), w/2)
        let tr = min(min(topRight, h/2), w/2)
        let bl = min(min(bottomLeft, h/2), w/2)
        let br = min(min(bottomRight, h/2), w/2)

        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}
