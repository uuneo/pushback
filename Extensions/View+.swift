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
    var maxX:Double = 10
	var onPress:((DragGesture.Value)->Void)? = nil
	var onRelease:((DragGesture.Value)->Void)? = nil
    
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
                            vibration()
                            onRelease?(result)
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
    func pressEvents(_ maxX:Double = 0.0, onPress: ((DragGesture.Value)->Void)? = nil, onRelease: ((DragGesture.Value)->Void)? = nil)-> some View{
        modifier(ButtonPress(maxX: maxX, onPress:onPress, onRelease: onRelease))
	}
    
    func button(_ maxX:Double = 0.0, onPress: ((DragGesture.Value)->Void)? = nil, onEnd: ((DragGesture.Value)->Void)? = nil)-> some View{
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


// MARK: - Conditional View
extension View {
    /// Whether the view should be empty.
    /// - Parameter bool: Set to `true` to show the view (return EmptyView instead).
    func showIf(_ bool: Bool) -> some View {
        modifier(ConditionalView(show: [bool]))
    }
    
    /// returns a original view only if all conditions are true
    func showIf(_ conditions: Bool...) -> some View {
        modifier(ConditionalView(show: conditions))
    }
}

struct ConditionalView: ViewModifier {
    
    let show: [Bool]
    
    func body(content: Content) -> some View {
        Group {
            if show.filter({ $0 == false }).count == 0 {
                content
            } else {
                EmptyView()
            }
        }
    }
}


extension View {
    /// Usually you would pass  `@Environment(\.displayScale) var displayScale`
    @MainActor func render(scale displayScale: CGFloat = 1.0) -> PlatformImage? {
        let renderer = ImageRenderer(content: self)
        
        renderer.scale = displayScale
        
#if os(iOS) || os(visionOS)
        let image = renderer.uiImage
#elseif os(macOS)
        let image = renderer.nsImage
#endif
        
        return image
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
    
    @ViewBuilder func if18 <Content: View>( transform: (Self) -> Content) -> some View {
        if #available(iOS 18.0, *){
            transform(self)
        }else{
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


extension View {
    func enchantify() -> some View {
        modifier(GradientForegroundStyle())
    }
    
    func enchantifyMoving() -> some View {
        self.modifier(MovingGradientForegroundStyle())
    }
}


extension View {
    /// Adds an underlying hidden button with a performing action that is triggered on pressed shortcut
    /// - Parameters:
    ///   - key: Key equivalents consist of a letter, punctuation, or function key that can be combined with an optional set of modifier keys to specify a keyboard shortcut.
    ///   - modifiers: A set of key modifiers that you can add to a gesture.
    ///   - action: Action to perform when the shortcut is pressed
    public func onKeyboardShortcut(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = .command,
        perform action: @escaping () -> Void
    ) -> some View {
        self.background(
            Button(action: action) {
                EmptyView()
            }
            .keyboardShortcut(key, modifiers: modifiers)
            .hidden()
        )
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


struct CancelButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .white : .gray)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ?
                    (configuration.isPressed ?
                        LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)) :
                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.7)
            .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}


struct SuccessButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .white : .gray)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ?
                    (configuration.isPressed ?
                        LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.8), Color.teal.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]), startPoint: .leading, endPoint: .trailing)) :
                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.7)
            .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}


struct ActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .white : .gray)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ?
                    (configuration.isPressed ?
                        LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)) :
                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.7)
            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
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
                
                }
            
            }
            
        } else {
            self
        }
        
    }
}

extension String{
    func stripMarkdown() -> Self {
        let patterns: [(pattern: String, replacement: String)] = [
            ("\\*\\*(.*?)\\*\\*", "$1"),   // **加粗**
            ("\\*(.*?)\\*", "$1"),         // *斜体*
            ("\\_(.*?)\\_", "$1"),         // _斜体_
            ("\\~\\~(.*?)\\~\\~", "$1"),   // ~~删除线~~
            ("\\`(.*?)\\`", "$1"),         // `代码`
            ("!\\[(.*?)\\]\\((.*?)\\)", "$1"), // ![图片](图片链接) -> 只保留文本
            ("\\[(.*?)\\]\\((.*?)\\)", "$1"), // [链接文本](链接地址) -> 只保留文本
            ("^#{1,6}\\s+", ""),           // # 标题（去掉 # 但保留内容）
            ("^[>|\\-\\+*]\\s+", ""),      // > 引用、- 无序列表、+ 无序列表、* 无序列表（去掉前缀）
            ("\\d+\\.\\s+", ""),           // 有序列表 1.（去掉前缀）
            ("\\[\\s?[x]?\\s?\\]", ""),    // 任务列表 [ ] 和 [x]
            ("`[^`]+`", ""),               // `行内代码`
            ("```[\\s\\S]*?```", ""),      // ``` 代码块 ```
            ("---", ""),                   // --- 分割线
        ]
        
        var strippedText = self
        for pattern in patterns {
            strippedText = strippedText.replacingOccurrences(of: pattern.pattern, with: pattern.replacement, options: .regularExpression)
        }
        
        return strippedText
    }
}


struct ScrollToBottomDetector: ViewModifier {
    let onBottom: () -> Void

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollViewHeightKey.self, value: proxy.size.height)
            })
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .frame(height: 0)
                        .preference(key: ScrollBottomOffsetKey.self, value: geo.frame(in: .global).maxY)
                }
            )
            .onPreferenceChange(ScrollBottomOffsetKey.self) { bottomY in
                DispatchQueue.main.async {
                    let screenHeight = UIScreen.main.bounds.height
                    if bottomY < screenHeight + 20 {
                        onBottom()
                    }
                    
                }
            }
    }
}

struct ScrollBottomOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func onScrollToBottom(perform: @escaping () -> Void) -> some View {
        self.modifier(ScrollToBottomDetector(onBottom: perform))
    }
}
