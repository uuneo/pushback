//
//  ToggleStateIntent.swift
//  InteractiveWidget
//
//  Created by Balaji on 11/06/23.
//

import SwiftUI
import AppIntents
import Defaults

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "配置"
    static var description = IntentDescription("表格配置选项")

    // An example configurable parameter.
    @Parameter(title: "反向样式", default: false)
    var isReverseChart: Bool
    
    @Parameter(title: "刷新间隔（分钟）", default: 15)
    var refreshIntervalMinutes: Int
    
    /// List of Colors for Chart Tint
    @Parameter(title: "提示颜色", query: ChartTintQuery())
    var chartTint: ChartTint?
}

struct ChartTint: AppEntity {
    /// Used Later For Queriying
    var id: UUID = .init()
    /// Color Title
    var name: String
    /// Color Value
    var color: Color
    
    static var defaultQuery = ChartTintQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "图表颜色"
    var displayRepresentation: DisplayRepresentation {
        return .init(title: "\(name)")
    }
}

struct ChartTintQuery: EntityQuery {
    func entities(for identifiers: [ChartTint.ID]) async throws -> [ChartTint] {
        /// Filtering Using ID
        return chartTints.filter { tint in
            identifiers.contains(where: { $0 == tint.id })
        }
    }
    
    func suggestedEntities() async throws -> [ChartTint] {
        return chartTints
    }
    
    func defaultResult() async -> ChartTint {
        return chartTints.first!
    }
}

var chartTints: [ChartTint] = [
    .init(name: String(localized: "红色"), color: .red),
    .init(name: String(localized: "蓝色"), color: .blue),
    .init(name: String(localized: "绿色"), color: .green),
    .init(name: String(localized: "紫色"), color: .purple)
]
