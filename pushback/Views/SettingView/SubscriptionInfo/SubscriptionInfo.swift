//
//  SubscriptionInfo.swift
//  pushback
//
//  Created by He Cho on 2024/11/21.
//

import Foundation
import Foundation

extension TimeInterval {
	static var day: TimeInterval = 24 * 60 * 60
}


struct SubscriptionInfo {
	var canAccessContent: Bool
	var isEligibleForTrial: Bool
	var subscriptionState: SubscriptionState
	
	init(canAccessContent: Bool, isEligibleForTrial: Bool, subscriptionState: SubscriptionState) {
		self.canAccessContent = canAccessContent
		self.isEligibleForTrial = isEligibleForTrial
		self.subscriptionState = subscriptionState
	}
}

// Preview Stub
extension SubscriptionInfo {
	static var stubNoAccess: SubscriptionInfo {
		SubscriptionInfo(canAccessContent: false, isEligibleForTrial: true, subscriptionState: .notSubscribed)
	}
	static var stubWithAccess: SubscriptionInfo {
		SubscriptionInfo(canAccessContent: true, isEligibleForTrial: false, subscriptionState: .subscribed(endDate: .now + .day * 7))
	}
}
