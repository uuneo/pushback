//
//  OptionsProvider.swift
//  Bark
//
//  Created by huangfeng on 2/21/25.
//  Copyright © 2025 Fin. All rights reserved.
//
import AppIntents
import Defaults





struct ServerAddressProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        Defaults[.servers].map { $0.server() }
    }
    
    func defaultResult() async -> String? {
        Defaults[.servers].first?.server()
    }
}


struct SoundOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let (customSounds , defaultSounds) = AudioManager.shared.getFileList()
        
        return (customSounds + defaultSounds).map {
            $0.deletingPathExtension().lastPathComponent
        }
    }
    
    func defaultResult() async -> String? {
        return "xiu"
    }
}


enum LevelTitle: String, CaseIterable {
    case passive
    case active
    case timeSensitive
    case critical

    var name: String {
        switch self {
        case .passive: return String(localized: "静默通知")
        case .active: return String(localized: "正常通知")
        case .timeSensitive: return String(localized: "即时通知")
        case .critical: return String(localized: "重要通知")
        }
    }

    // 🔁 从 displayName 获取 rawValue（如："静默通知" -> "passive"）
    static func rawValue(fromDisplayName name: String) -> String? {
        return LevelTitle.allCases.first(where: {$0.name == name})?.rawValue
    }
}


struct LevelClassProvider:  DynamicOptionsProvider{
    func results() async throws -> [String] {
        return LevelTitle.allCases.map { level in
            level.name
        }
    }
    
    func defaultResult() async -> String? {
        return LevelTitle.active.name
    }
}


struct VolumeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [Int] {
        return Array(0...10)
    }
    
    func defaultResult() async -> Int? {
        return 5
    }
}


struct APIPushToDeviceResponse: Codable {
    let code: Int
    let message: String
    let timestamp: Int
}


