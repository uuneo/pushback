//
//  View+.swift
//  Meow
//
//  Created by uuneo 2024/8/9.
//

import Foundation
import SwiftUI
import Combine


struct CustomForegroundStyleModifier: ViewModifier{
    @Environment(\.colorScheme) var colorScheme
    var s1: Color
    var s2: Color? = nil
    var s3: Color? = nil
    
    var primaryColor:Color{
        colorScheme == .dark ? .white : .black
    }
    var primary: Color{
        s1 == .primary ? primaryColor : s1
    }
    
    var secondary: Color?{
        if let s2 = s2 {
            return s2 == .primary ? primaryColor : s2
        }
        return nil
    }
    
    var tertiary:Color?{
        if let s3 = s3 {
            return s3 == .primary ? primaryColor : s3
        }
        return nil
    }
    
    func body(content: Content) -> some View {
        if let secondary, let tertiary{
            content
                .foregroundStyle(primary, secondary, tertiary)
        }else if let secondary{
            content
                .foregroundStyle(primary, secondary)
        }else{
            content
                .foregroundStyle(primary)
        }
       
            
    }
    
    
}

extension View{
    func customForegroundStyle(_ s1: Color, _ s2: Color? = nil ,_ s3: Color? = nil) -> some View{
        modifier(CustomForegroundStyleModifier(s1: s1,s2: s2,s3: s3))
    }
}


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

// MARK: - buttons 视图
struct ButtonPress: ViewModifier{
    var releaseStyles:Double = 0.0
    var maxX:Double = 0.0
    var changeHaptic:Bool = false
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

                        if !ispress && changeHaptic{
                            Haptic.impact()
                            onPress?(result)
                        }
                        
                        self.ispress = true
                        
                        if !changeHaptic{
                            onPress?(result)
                        }
						
                        if releaseStyles > 0.0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + releaseStyles ){
                                self.ispress = false
                            }
                        }
					})
                    .onEnded({ result in
                        self.ispress = false
                        if changeHaptic{
                            if let success = onRelease?(result), success{
                                Haptic.impact()
                            }
                        }else{
                            if abs(result.translation.width) <= maxX ,
                               let success = onRelease?(result), success{
                                Haptic.impact()
                            }
                        }
                    })
			)
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
    var background: Bool = true
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
                        .foregroundStyle(.tint, .secondary)
                        .onTapGesture {
                            complete?()
                            Haptic.impact()
                        }
					Spacer()
				}
			)
			.padding()
			.padding(.leading, 43)
            .if(background){ view in
                view
                    .background(.ultraThinMaterial)
            }
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

struct ViewExtractHelper: UIViewRepresentable {
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
    
    case none
        
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
        }.VButton(onRelease:{_ in
            return action()
        })
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
    
    @ViewBuilder func diff<Content: View>(transform: (Self) -> Content) -> some View {
        transform(self)
    }
    

    
    func slideFadeIn(show: Bool, offset: Double = 10) -> some View {
        self.modifier(SlideFadeIn(show: show, offset: offset))
    }
    
    func customField(icon: String,_ background:Bool = true, complete: (()-> Void)? = nil) -> some View {
        self.modifier(TextFieldModifier( icon: icon,background: background, complete: complete))
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
    
    func VButton(_ maxX:Double = 0.0,
                 release:Double = 0.0,
                 changeHaptic:Bool = false,
                 onPress: ((DragGesture.Value)->Void)? = nil,
                 onRelease: ((DragGesture.Value)->Bool)? = nil)-> some View{
        modifier(ButtonPress(releaseStyles: release, maxX: maxX, changeHaptic: changeHaptic,onPress:onPress, onRelease: onRelease))
    }
    
    func VButton(changeHaptic:Bool = false, onRelease: @escaping (DragGesture.Value)->Bool)-> some View{
        modifier(ButtonPress(releaseStyles: 0, maxX: 0, changeHaptic:changeHaptic, onPress:nil, onRelease: onRelease))
    }
    
    @ViewBuilder
    func customPresentationCornerRadius(_ radius:CGFloat)-> some View{
        if #available(iOS 16.4, *){
            self
                .presentationCornerRadius(radius)
        }else {
            self
        }
    }
    
    @ViewBuilder
    func symbolEffect(_ type:sybolEffectType = .bounce, delay: Double? = nil) -> some View {
        
        
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
                    self.symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(repeatBehavior1))
                case .wiggle:
                    self.symbolEffect(.wiggle.up.byLayer, options: .repeat(repeatBehavior1))
                case .replace:
                    self.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .repeat(repeatBehavior1)))
                case .replaceblack:
                    self.contentTransition(.symbolEffect(.replace))
                case .none:
                    self
                
                }
            }
            
        } else {
            self
        }
        
    }
    
}


enum ScrollDirection {
    case up, down
}

struct VerticalScrollDetector: ViewModifier {
    var onScroll: (ScrollDirection, CGFloat) -> Void

    @State private var lastOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .global).minY)
            })
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newY in
                let delta = newY - lastOffset
                if delta != 0 {
                    let direction: ScrollDirection = delta > 0 ? .down : .up
                    onScroll(direction, newY)
                    lastOffset = newY
                }
            }
    }

    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

extension View {
    func onVerticalScrollChange(
        perform: @escaping (ScrollDirection, CGFloat) -> Void
    ) -> some View {
        self.modifier(VerticalScrollDetector(onScroll: perform))
    }
}






