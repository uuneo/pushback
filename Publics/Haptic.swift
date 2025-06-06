//
//  Haptic.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//

import UIKit

enum Haptic {
    
    private static var lastImpactTime: Date?
    private static var minInterval: TimeInterval = 0.1 // 最小震动间隔

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
                       limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType,
                       limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection(limitFrequency: Bool = false) {
        guard canTrigger(limitFrequency: limitFrequency) else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private static func canTrigger(limitFrequency: Bool) -> Bool {
        guard limitFrequency else { return true }
        let now = Date()
        if let last = lastImpactTime, now.timeIntervalSince(last) < minInterval {
            return false
        }
        lastImpactTime = now
        return true
    }
}
