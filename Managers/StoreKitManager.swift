//
//  File name:     StoreKitManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/23.


import StoreKit

@MainActor
final class AppState: ObservableObject {
	@Published private(set) var products: [Product] = []
	@Published private(set) var activeTransactions: Set<StoreKit.Transaction> = []
	@Published var subscriptionInfo: SubscriptionInfo = .stubNoAccess // Default to no access

	private var updatesTask: Task<Void, Never>? // Task for listening to transaction updates

	init() {
		Task {
			await fetchProducts()
			await loadActiveTransactions()
			await updateSubscriptionInfo()
		}
		startTransactionListener() // Start listening for transaction updates
	}

	deinit {
		updatesTask?.cancel() // Ensure the task is cancelled when the object is deallocated
	}

	// Fetch available products
	func fetchProducts() async {
		do {
			products = try await Product.products(
				for: [
					"pushback_monthly_18_intro7days_free",
					"pushback_yearly_128_intro7days_free",
				]
			)
		} catch {
			print("Failed to fetch products: \(error.localizedDescription)")
			products = []
		}
	}

	// 购买产品
	func purchase(_ product: Product) async throws {
		let result = try await product.purchase()
		switch result {
			case .success(let verificationResult):
				// 安全地提取 Transaction
				if let transaction = try? verificationResult.payloadValue {
					await addTransaction(transaction) // 处理该交易
					Toast.shared.present(title: String(localized: "购买成功"), symbol: .error)
				} else {
					print("交易验证失败。")
					Toast.shared.present(title: String(localized: "交易验证失败。"), symbol: .error)
				}
			case .userCancelled:
				print("用户取消了购买。")
				Toast.shared.present(title: String(localized: "用户取消了购买。"), symbol: .question)
			case .pending:
				print("购买正在等待中。")
				Toast.shared.present(title: String(localized: "购买正在等待中。"), symbol: .info)
			@unknown default:
				print("出现了未知的购买结果。")
				Toast.shared.present(title: String(localized: "出现了未知的购买结果。"), symbol: .error)
		}
	}
	// 获取当前的有效交易（包括之前完成的交易）
	func loadActiveTransactions() async {
		var activeTransactions: Set<StoreKit.Transaction> = []

		// 迭代当前有效的交易
		for await entitlement in StoreKit.Transaction.currentEntitlements {
			// 提取并验证 transaction
			if let transaction = try? entitlement.payloadValue {
				activeTransactions.insert(transaction)
			} else {
				print("交易验证失败。")
			}
		}

		// 更新主线程上的 activeTransactions
		await MainActor.run {
			self.activeTransactions = activeTransactions
		}
		// 更新订阅信息
		await updateSubscriptionInfo()
	}

	// Add a transaction to the active list and finish the transaction
	private func addTransaction(_ transaction: StoreKit.Transaction) async {
		activeTransactions.insert(transaction)
		await transaction.finish() // Finish the transaction after processing
		await updateSubscriptionInfo() // Update subscription info after adding a transaction
	}

	// Listen to transaction updates and handle them
	private func startTransactionListener() {
		updatesTask = Task {
			for await update in StoreKit.Transaction.updates {
				if let transaction = try? update.payloadValue {
					await addTransaction(transaction)
				} else {
					print("Transaction update verification failed.")
				}
			}
		}
	}

	// Update subscription information based on active transactions
	private func updateSubscriptionInfo() async {
		let sortedTransactions = activeTransactions.sorted {
			switch ($0, $1) {
				case let (transaction1, transaction2):
					return transaction1.purchaseDate > transaction2.purchaseDate
			}
		}

		// Determine the subscription state based on active transactions
		for transaction in sortedTransactions {
			switch transaction.productID {
				case "pushback_monthly_18_intro7days_free", "pushback_yearly_128_intro7days_free":
					if let endDate = transaction.expirationDate {
						let subscriptionState: SubscriptionState
						if endDate > Date() {
							subscriptionState = .subscribed(endDate: endDate)
						} else {
							subscriptionState = .inTrial(endDate: endDate)
						}
						subscriptionInfo = SubscriptionInfo(
							canAccessContent: true,
							isEligibleForTrial: false,
							subscriptionState: subscriptionState
						)

						debugPrint(subscriptionInfo)
						return
					}
				default:
					break
			}
		}

		// If no valid subscriptions found, set the state to not subscribed
		subscriptionInfo = SubscriptionInfo(
			canAccessContent: false,
			isEligibleForTrial: true,
			subscriptionState: .notSubscribed
		)
	}

	// 恢复以前的购买
	func restorePurchases() async {
		var restoredTransactions: [StoreKit.Transaction] = []

		// 获取所有当前的有效交易（之前完成的交易）
		for await entitlement in StoreKit.Transaction.currentEntitlements {
			// 提取并验证 transaction
			if let transaction = try? entitlement.payloadValue {
				restoredTransactions.append(transaction)
				Toast.shared.present(title: String(localized: "恢复成功"), symbol: .success)
			} else {
				print("交易验证失败。")
				Toast.shared.present(title: String(localized: "交易验证失败。"), symbol: .error)
			}
		}

		// 处理每一个恢复的交易
		for transaction in restoredTransactions {
			await addTransaction(transaction)
		}

		// 恢复购买后更新订阅信息
		await updateSubscriptionInfo()
	}

	// Expose subscriptionInfo for UI updates
	func getSubscriptionInfo() -> SubscriptionInfo {
		return subscriptionInfo
	}
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

enum SubscriptionState {
	case notSubscribed
	case inTrial(endDate: Date)
	case subscribed(endDate: Date)
}

extension SubscriptionState: CustomStringConvertible {
	public var description: String {

		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm  MM/dd/yyyy"


		switch self {
			case .notSubscribed:return  String(localized: "未订阅")
			case let .inTrial(endDate):return  String(localized:"试用期至 \(formatter.string(from: endDate))")
			case let .subscribed(endDate): return String(localized:"订阅至 \(formatter.string(from: endDate))")
		}
	}
}

extension TimeInterval {
	static var day: TimeInterval = 24 * 60 * 60
}
