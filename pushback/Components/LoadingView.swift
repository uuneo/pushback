//
//  LoadingBubbleView.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/2.
//


import SwiftUI
import Combine

struct StreamingLoadingView: View {
    let isAwait:Bool
    @State private var dots = ""
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?

    var body: some View {
        HStack(spacing: 4) {
            // AI头像或图标
            Image(systemName: "brain")
                .foregroundColor(.blue)
                .imageScale(.medium)
            
            // 思考中的动画点
            Text((isAwait ?  "思考中" : "正在输入") + "\(dots)")
                .foregroundColor(.secondary)
                .font(.system(.subheadline))
                .animation(.bouncy, value: dots)
        }
        .onAppear {
            self.timerCancellable = self.timer.connect()
        }
        .onDisappear {
            self.timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}
/*
使用方法：
  if chatStore.isLoading {
      HStack {
          LoadingBubbleView()
              .padding(.horizontal)
          Spacer()
      }
  }
*/
struct LoadingBubbleView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingBubbleView()
}
