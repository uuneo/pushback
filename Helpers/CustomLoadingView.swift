//
//  CustomLoadingView.swift
//  CustomLoadingScreen
//
//  Created by Balaji Venkatesh on 31/05/25.
//

import SwiftUI

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

/// Tried using @resultbuilder to create a custom builder, but without any reason it's just crashing :(
struct LoadingItem {
    var image: String
    var imageForeground: Color
    var imageBackground: Color
    /// Add more properties as per your needs!
}

struct CustomLoadingView<Center: View>: View {
    var tint: Color
    var items: [LoadingItem]
    @ViewBuilder var center: Center
    /// View Properties
    @State private var isRotating: Bool = false
    @State private var activeIndex: Int?
    @State private var startAnimation: Bool = false
    @Namespace private var namespace
    var body: some View {
        GeometryReader {
            let size = $0.size
            /// Since the size is hard-coded for this explicit animation, that's why resizing view using scale, instead of frame()!
            /// To fit/shrink the loading view into the given bounds
            let scaledValue = size.width / (320 + expandedCircleSize + 15)
            
            ZStack {
                center
                
                GeometryReader {
                    let size = $0.size
                    
                    ZStack {
                        ForEach(0..<count, id: \.self) { index in
                            let item = items[index % items.count]
                            let rotation = CGFloat(index) * rotationMultiplier
                            
                            CustomRing(index, item: item)
                                .compositingGroup()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: -(size.width - 60) / 2)
                                .rotationEffect(.init(degrees: rotation))
                        }
                    }
                    .compositingGroup()
                }
                .rotationEffect(.init(degrees: isRotating ? 360 : 0))
            }
            .frame(width: 320, height: 320)
            .compositingGroup()
            .scaleEffect(scaledValue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            guard !startAnimation else { return }
            startAnimation = true
            
            withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                isRotating.toggle()
            }
            
            Task {
                await loopEffect()
            }
        }
        .onDisappear {
            startAnimation = false
        }
    }
    
    @ViewBuilder
    private func CustomRing(_ index: Int, item: LoadingItem) -> some View {
        let animate = activeIndex == index
        
        VStack(spacing: 8) {
            HStack(spacing: animate ? 10 : 26) {
                Circle()
                    .fill(tint)
                    .frame(width: 15, height: 15)
                
                /// This is ring which is getting expanded!
                Circle()
                    .fill(tint)
                    .overlay {
                        ItemView(index: index, item: item)
                    }
                    .clipShape(.circle)
                    .offset(y: animate ? -10 : 0)
                    .overlay {
                        ExpandedCircleOuterRingView(index: index)
                    }
                    .frame(
                        width: animate ? expandedCircleSize : 15,
                        height: animate ? expandedCircleSize : 15
                    )
                
                Circle()
                    .fill(tint)
                    .frame(width: 15, height: 15)
            }
            
            HStack(spacing: 16) {
                CustomCircleView(1, index: index, radius: 12)
                
                CustomCircleView(2, index: index, radius: 12)
                
                CustomCircleView(6, index: index, radius: 12)
                
                CustomCircleView(7, index: index, radius: 12)
            }
            .padding(.top, 3)
            
            HStack(spacing: 20) {
                CustomCircleView(3, index: index, radius: 12)
                CustomCircleView(4, index: index, radius: 12)
                CustomCircleView(5, index: index, radius: 12)
            }
            
            /// This batch don't require matched geometry effect!
            HStack(spacing: 15) {
                Circle()
                    .frame(width: 10, height: 10)
                
                Circle()
                    .frame(width: 10, height: 10)
            }
            .offset(y: animate ? -30 : 0)
            .overlay(alignment: .leading) {
                Circle()
                    .frame(width: 10, height: 10)
                    .offset(x: -25, y: animate ? -22 : 8)
            }
            .foregroundStyle(tint)
        }
    }
    
    @ViewBuilder
    func CustomCircleView(_ id: Int, index: Int, radius: CGFloat) -> some View {
        ZStack {
            if activeIndex != index {
                Circle()
                    .fill(tint)
                    .matchedGeometryEffect(id: "\(index)-\(id)", in: namespace)
                    .frame(width: radius, height: radius)
                    .transition(.offset(y: 1))
            } else {
                Circle()
                    .foregroundStyle(.clear)
                    .frame(width: radius, height: radius)
            }
        }
    }
    
    @ViewBuilder
    func ItemView(index: Int, item: LoadingItem) -> some View {
        let rotation = CGFloat(index) * rotationMultiplier
        let isAnimated = activeIndex == index
        
        ZStack {
            Circle()
                .fill(item.imageBackground.gradient)
            
            Image(systemName: item.image)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(item.imageForeground)
                .scaleEffect(isAnimated ? 1 : 0.1)
                /// Avoiding image rotation!
                .rotationEffect(.init(degrees: -rotation))
                .rotationEffect(.init(degrees: isRotating ? -360 : 0))
        }
        .opacity(isAnimated ? 1 : 0)
    }
    
    @ViewBuilder
    func ExpandedCircleOuterRingView(index: Int) -> some View {
        let isAnimated = activeIndex == index
        
        ZStack {
            if isAnimated {
                ForEach(1...7, id: \.self) { id in
                    let rotation = CGFloat(id) * 23
                    let isSmallSize = id % 2 != 0
                    
                    Circle()
                        .matchedGeometryEffect(id: "\(index)-\(id)", in: namespace)
                        .frame(width: isSmallSize ? 6 : 10, height: isSmallSize ? 6 : 10)
                        .offset(x: -45)
                        .rotationEffect(.init(degrees: -rotation))
                }
            }
        }
    }
    
    private func loopEffect() async {
        /// Avoids infinite loop!
        guard startAnimation else { return }
        
        withAnimation(animation) {
            activeIndex = 1
        }
        
        /// If the count is changed from 8, these values should also be corrected!
        await switchNext(3)
        await switchNext(5)
        await switchNext(7)
        try? await Task.sleep(for: .seconds(delayBetweenSwitch))
        await loopEffect()
    }
    
    private func switchNext(_ index: Int) async {
        try? await Task.sleep(for: .seconds(delayBetweenSwitch))
        
        withAnimation(animation) {
            activeIndex = index
        }
    }
    
    /// Count is hard-coded for this specific animation effect!
    /// Value 8 will give the best reuslt
    private var count: Int {
        return 8
    }
    
    private var rotationMultiplier: CGFloat {
        return 360 / CGFloat(count)
    }
    
    private var expandedCircleSize: CGFloat {
        return 75
    }
    
    /// Modify the animation as per your needs!
    private var animation: Animation {
        .smooth(duration: 0.6, extraBounce: 0)
    }
    
    private var delayBetweenSwitch: CGFloat {
        return 3
    }
    
    private var rotationDuration: CGFloat {
        return 28
    }
}


#Preview {
    ContentView()
}
