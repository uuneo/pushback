//
//  ServerCardView.swift
//  pushback
//
//  Created by He Cho on 2024/10/30.
//

import SwiftUI


struct ServerCardView:View {
	@StateObject private var manager = PushbackManager.shared
	var item: PushServerModal
	var isCloud:Bool = false
	
	
	var body: some View {
		HStack(alignment: .center){
			
			if !isCloud {
				VStack{
					
					if item.status{
						Image(systemName: "antenna.radiowaves.left.and.right")
							.scaleEffect(1.5)
							.symbolRenderingMode(.palette)
							.foregroundStyle( Color.primary, .green)
						
					}else{
						Image(systemName: "antenna.radiowaves.left.and.right.slash")
							.scaleEffect(1.5)
							.symbolRenderingMode(.palette)
							.foregroundStyle(Color.primary, .red)
							
						
					}
					
				}
				.padding(.horizontal,5)
			}
			
			
			VStack{
				HStack(alignment: .bottom){
					Text(String(localized: "服务器") + ":")
						.font(.system(size: 10))
						.frame(width: 40)
					Text(item.name)
						.font(.headline)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
					Spacer()
				}
				
				HStack(alignment: .bottom){
					Text("KEY:")
						.frame(width:40)
					Text(item.key)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
					Spacer()
				} .font(.system(size: 10))
				
			}
			Spacer()
			
			
			
			if !isCloud{
				Image(systemName: "doc.on.doc")
					.symbolRenderingMode(.palette)
					.foregroundStyle( .tint, Color.primary)
					.onTapGesture{
						Toast.shared.present(title: String(localized: "复制成功"), symbol: .copy)
						manager.copy( item.url + "/" + item.key)
					}
				
			}
			
			
		}
	}
}
