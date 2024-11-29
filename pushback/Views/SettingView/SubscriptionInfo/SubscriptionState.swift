//
//  SubscriptionState.swift
//  pushback
//
//  Created by He Cho on 2024/11/21.
//

import Foundation

enum SubscriptionState {
	case notSubscribed
	case inTrial(endDate: Date)
	case subscribed(endDate: Date)
}

extension SubscriptionState: CustomStringConvertible {
	public var description: String {
		switch self {
			case .notSubscribed: "未订阅"
			case let .inTrial(endDate): "试用期至 \(endDate.formatted(date: .abbreviated, time: .shortened))"
			case let .subscribed(endDate): "订阅至 \(endDate.formatted(date: .abbreviated, time: .shortened))"
		}
	}
}
