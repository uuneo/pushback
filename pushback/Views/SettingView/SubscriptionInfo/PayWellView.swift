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
				
		}else{
			
			
			if showPayWall{
				content
					.disabled(disable)
					.presentPaywallIfNeeded(requiredEntitlementIdentifier: RCConstants.premium){ customInfo in
						debugPrint("\(customInfo)")
					}onDismiss: {
						self.showPayWall = false
					}
			}else{
				content
					.disabled(disable)
					.overlay{
						ZStack(alignment: .topTrailing){
							Color.white
								.opacity(0.1)
								.blur(radius: 10)
							VStack{
								Spacer()
								Image(systemName:  "lock.shield")
									.symbolRenderingMode(.palette)
									.foregroundStyle(.tint, Color.primary)
									.background(
										Circle()
											.fill(.ultraThinMaterial)
									)
									.padding(.trailing, 15)
								Spacer()
							}
							
						}
						
					}
					.onTapGesture {
						self.showPayWall.toggle()
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

