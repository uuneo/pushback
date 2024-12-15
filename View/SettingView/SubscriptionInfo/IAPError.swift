//
//  IAPError.swift
//  RevenueCatSubscriptionDemo
//
//  Created by  on 2023/12/10.
//

import Foundation
import os


enum Logger {
	static let iapService = os.Logger(subsystem: "me.uuneo.Meoworld", category: "IAP Service")
}


enum IAPError: Error {
    case verificationFailed
    case noAvailableStoreProduct
    case missingEntitlement
}
