//
//  HapticsManager.swift
//  Meow
//
//  Created by He Cho on 2024/8/30.
//

import Foundation
import CoreHaptics
import UIKit


class HapticsManager{
    static let shared = HapticsManager()
    private var hapticEngine: CHHapticEngine?
    
    init() {
        createHapticEngine()
    }
    
    private func createHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("无法创建或启动 Haptic Engine: \(error)")
        }
    }
    
    
    func complexSuccess() {
        // 确保设备支持震动反馈
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()
        
        // 创建一个强烈的，锐利的震动
        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }
        
        // 将震动事件转换成模式，立即播放
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
    
    
    
    func stopEngine() {
        hapticEngine?.stop(completionHandler: { error in
            if let error = error {
                print("Haptic Engine 停止失败: \(error)")
            }
        })
    }
    
    
    func restartEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Haptic Engine 重启失败: \(error)")
        }
    }
    
    
    // 触发震动反馈
    static func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // 触发选择震动反馈
    static func triggerSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // 触发通知震动反馈
    static func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
}
