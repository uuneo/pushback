//
//  VolumePeakView.swift
//  pushme
//
//  Created by lynn on 2025/7/27.
//


import SwiftUI
import UIKit



struct VolumePeakView: View {
    var micLevel: Float       // 当前音量值（0~6）
    var maxLevel: Float = 100.0 // 最大音量值，对应全亮

   
    @State private var animatedLevel: Int = 0
    @State private var timer: Timer?
    var lineCount:Int = 50
    var targetLevel: Int {
        let normalized = min(max(micLevel, 0), maxLevel)
        return Int((normalized / maxLevel) * Float(lineCount))
    }
    
    

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...lineCount, id: \.self) { index in
                Capsule()
                    .fill(setColor(animatedLevel, index: index))
                    .frame(width: 4, height: 12)
            }
        }
        .onChange(of: micLevel) { newValue in
            Queue.mainQueue().async {
                animateToTarget()
            }
        }
        .onAppear{
            animateToTarget()
        }
    }
    
    func setColor(_ input: Int, index: Int) -> Color{
        
        guard micLevel > 0 else { return .gray.opacity(0.3) }
    
        if (lineCount - index) < animatedLevel {
            if input > (lineCount / 10 * 9){
                return .red
            }else if input > (lineCount / 10 * 7){
                return .orange
            }else if input > 0{
                return .white
                
            }
        }
        
        
        return .gray.opacity(0.3)
    }

    func animateToTarget() {
        timer?.invalidate()
        let diff = targetLevel - animatedLevel
        let step = diff > 0 ? 1 : -1
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { t in
            if animatedLevel != targetLevel {
                animatedLevel += step
            } else {
                t.invalidate()
            }
        }
    }
}

#Preview {
    VolumePeakView(micLevel: 0)
}
