//
//  StaggeredView.swift
//  StaggeredAnimation
//
//  Created by Balaji Venkatesh on 26/03/25.
//

import SwiftUI

@available(iOS 18.0, *)
struct StaggeredView<Content: View>: View {
    var config: StaggeredConfig = .init()
    @ViewBuilder var content: Content
    var body: some View {
        Group(subviews: content) { collection in
            ForEach(collection.indices, id: \.self) { index in
                collection[index]
                    .transition(CustomStaggeredTransition(index: index, config: config))
            }
        }
    }
}

@available(iOS 17.0, *)
fileprivate struct CustomStaggeredTransition: Transition {
    var index: Int
    var config: StaggeredConfig
   
    func body(content: Content, phase: TransitionPhase) -> some View {
        let animationDelay: Double = min(Double(index) * config.delay, config.maxDelay)
        
        let isIdentity: Bool = phase == .identity
        let didDisappear: Bool = phase == .didDisappear
        let x: CGFloat = config.offset.width
        let y: CGFloat = config.offset.height
        
        let reverseX: CGFloat = config.disappearInSameDirection ? x : -x
        let disappearCheckX: CGFloat = config.noOffsetDisappearAnimation ? 0 : reverseX
        
        let reverseY: CGFloat = config.disappearInSameDirection ? y : -y
        let disappearCheckY: CGFloat = config.noOffsetDisappearAnimation ? 0 : reverseY
        
        let offsetX = isIdentity ? 0 : didDisappear ? disappearCheckX : x
        let offsetY = isIdentity ? 0 : didDisappear ? disappearCheckY : y
        
        content
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : config.blurRadius)
            .compositingGroup()
            .scaleEffect(isIdentity ? 1 : config.scale, anchor: config.scaleAnchor)
            .offset(x: offsetX, y: offsetY)
            .animation(config.animation.delay(animationDelay), value: phase)
    }
}

/// Config
struct StaggeredConfig {
    var delay: Double = 0.05
    var maxDelay: Double = 0.4
    var blurRadius: CGFloat = 6
    var offset: CGSize = .init(width: 0, height: 100)
    var scale: CGFloat = 0.95
    var scaleAnchor: UnitPoint = .center
    var animation: Animation = .interpolatingSpring
    var disappearInSameDirection: Bool = false
    var noOffsetDisappearAnimation: Bool = false
    /// Add more properties as per your needs!
}

#Preview {
    ContentView()
}
