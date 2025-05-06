//
//  PopOutView.swift
//  SlackHeaderAnimation
//
//  Created by Balaji Venkatesh on 09/04/25.
//

import SwiftUI

@available(iOS 17.0, *)
struct PopOutView<Header: View, Content: View>: View {
    @ViewBuilder var header: (Bool) -> Header
    @ViewBuilder var content: (Bool) -> Content
    /// View Properties
    @State private var sourceRect: CGRect = .zero
    @State private var showFullScreenCover: Bool = false
    @State private var animateView: Bool = false
    /// Finally Let's add some Haptics
    @State private var haptics: Bool = false
    var body: some View {
        header(animateView)
            .background(solidBackground(color: .gray, opacity: 0.1))
            .clipShape(.rect(cornerRadius: 10))
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                sourceRect = newValue
            }
            .contentShape(.rect)
            /// Hiding Source View when Destination Popout view is visible
            .opacity(showFullScreenCover ? 0 : 1)
            .onTapGesture {
                haptics.toggle()
                toggleFullScreenCover()
            }
            .fullScreenCover(isPresented: $showFullScreenCover) {
                PopOutOverlay(
                    sourceRect: $sourceRect,
                    animateView: $animateView,
                    header: header,
                    content: content
                ) {
                    withAnimation(.easeInOut(duration: 0.25), completionCriteria: .removed) {
                        animateView = false
                    } completion: {
                        toggleFullScreenCover()
                    }
                }
            }
            .sensoryFeedback(.impact, trigger: haptics)
    }
    
    private func toggleFullScreenCover() {
        /// Toggles Full-Screen-Cover without any Animation
        var transaction = Transaction()
        transaction.disablesAnimations = true
        
        withTransaction(transaction) {
            showFullScreenCover.toggle()
        }
    }
}

/// Custom Overlay View (Which Actually is a Full-Screen-Cover)!
/// Thus making this to be appear at the top of the window!
@available(iOS 17.0, *)
fileprivate struct PopOutOverlay<Header: View, Content: View>: View {
    @Binding var sourceRect: CGRect
    @Binding var animateView: Bool
    @ViewBuilder var header: (Bool) -> Header
    @ViewBuilder var content: (Bool) -> Content
    var dismissView: () -> ()
    /// View Properties
    @State private var edgeInsets: EdgeInsets = .init()
    @State private var scale: CGFloat = 1
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                /// Close Button
                if animateView {
                    Button(action: dismissView) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.primary)
                            .contentShape(.rect)
                    }
                }
                
                header(animateView)
            }
            
            if animateView {
                content(animateView)
                    .transition(.blurReplace)
            }
        }
        /// Taking full-available space on expanded mode
        .frame(maxWidth: animateView ? .infinity : nil, alignment: .leading)
        .padding(animateView ? 15 : 0)
        .background {
            ZStack {
                solidBackground(color: .gray, opacity: 0.1)
                    .opacity(!animateView ? 1 : 0)
                
                Rectangle()
                    .fill(.background)
                    .opacity(animateView ? 1 : 0)
            }
        }
        .clipShape(.rect(cornerRadius: animateView ? 20 : 10))
        .shadow(radius: animateView ? 10 : 0)
        .scaleEffect(scale, anchor: .top)
        .frame(
            width: animateView ? nil : sourceRect.width,
            height: animateView ? nil : sourceRect.height
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .offset(
            x: animateView ? 0 : sourceRect.minX,
            y: animateView ? 0 : sourceRect.minY
        )
        .padding(animateView ? 15 : 0)
        /// Top Safe Area Padding
        .padding(.top, animateView ? edgeInsets.top : 0)
        .ignoresSafeArea()
        .presentationBackground {
            /// Required for scale calculation
            GeometryReader {
                let size = $0.size
                Rectangle()
                    .fill(Color.primary.opacity(animateView ? 0.5 : 0))
                    .onTapGesture {
                        dismissView()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                let height = value.translation.height
                                let scale = height / size.height
                                let applyingRatio: CGFloat = 0.1
                                self.scale = 1 + (scale * applyingRatio)
                            }).onEnded({ value in
                                let velocityHeight = value.velocity.height / 5
                                let height = value.translation.height + velocityHeight
                                let scale = height / size.height
                                
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    self.scale = 1
                                }
                                
                                if -scale > 0.5 {
                                    dismissView()
                                }
                            })
                    )
            }
        }
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            guard !animateView else { return }
            edgeInsets = newValue
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.25)) {
                    animateView = true
                }
            }
        }
    }
}

extension View {
    fileprivate func solidBackground(color: Color, opacity: CGFloat) -> some View {
        Rectangle()
            .fill(.background)
            .overlay {
                Rectangle()
                    .fill(color.opacity(opacity))
            }
    }
}


#Preview {
    ContentView()
}

