//
//  PayWellView.swift
//  pushback
//
//  Created by He Cho on 2024/11/23.
//

import SwiftUI
import RevenueCatUI


struct PayWellViewModifier: ViewModifier {
	var disable:Bool
	@State private var showPayWall:Bool = false
	@ObservedObject private var manager = PushbackManager.shared
	func body(content: Content) -> some View {
		
		
		if let premiumSubscriptionInfo = manager.premiumSubscriptionInfo,
		   premiumSubscriptionInfo.canAccessContent {
			content
				.onAppear{
					debugPrint(premiumSubscriptionInfo)
				}
		}else{
			
			
			if showPayWall{
				content
					.disabled(disable)
					.presentPaywallIfNeeded(requiredEntitlementIdentifier: RCConstants.premium){ customInfo in
						debugPrint("genggai:\(customInfo)")
					}onDismiss: {
						self.showPayWall = false
					}
			}else{
				content
					.disabled(disable)
					.overlay(alignment: .topTrailing){
						Button{
							self.showPayWall.toggle()
						}label: {
							Image(systemName:  "lock.shield")
								
								.symbolRenderingMode(.palette)
								.foregroundStyle(.tint, Color.primary)
								.padding(5)
								.background(
									Circle()
										.fill(.ultraThinMaterial)
								)
						}
					}
					
			}
			
			
			
			
		}
		
		
		
		
		
		
		
	}
	
	
}

extension View{
	func showPayWell(_ disable:Bool = true) -> some View{
		self.modifier(PayWellViewModifier(disable:disable))
	}
}

