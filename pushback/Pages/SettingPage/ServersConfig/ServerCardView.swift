//
//  ServerCardView.swift
//  pushback
//
//  Created by uuneo 2024/10/30.
//

import SwiftUI
import Defaults

struct ServerCardView:View {
	@StateObject private var manager = PushbackManager.shared
	var item: PushServerModel
	var isCloud:Bool = false
	
	
	var body: some View {
		HStack(alignment: .center){

			if !isCloud {
				Image(systemName:  "antenna.radiowaves.left.and.\(item.status ?  "right" : "slash")")
					.scaleEffect(1.5)
					.symbolRenderingMode(.palette)
					.foregroundStyle( Color.primary, item.status ? .green : .red)
					.padding(.horizontal,5)
			}else{
				Image(systemName: "link.icloud")
					.scaleEffect(1.5)
					.symbolRenderingMode(.palette)
					.foregroundStyle( Color.primary, .green)
			}

			VStack{
				HStack(alignment: .bottom){
					Text( String(localized: "服务器") + ":")
						.font(.system(size: 10))
						.frame(width: 40)
                        .foregroundStyle(.foreground)
					Text(item.name)
						.font(.headline)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
                        .foregroundStyle(.foreground)
					Spacer()
				}
				
				HStack(alignment: .bottom){
					Text("Key:")
						.frame(width:40)
                        .foregroundStyle(.foreground)
					Text(item.key)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
                        .foregroundStyle(.foreground)
					Spacer()
				} .font(.system(size: 10))
				
			}
			Spacer()
			
			
			
            Image(systemName: "cursorarrow.click.2")
                .symbolRenderingMode(.palette)
                .foregroundStyle( .tint, Color.primary)

			
		}
	}
}
