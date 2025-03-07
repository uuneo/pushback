//
//  Date+Extension.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/1.
//

import SwiftUI





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
