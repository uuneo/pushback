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
    @State private var textAnimation:Bool = false
	var item: PushServerModel
	var isCloud:Bool = false
	
    var complete:() -> Void
	
	var body: some View {
		HStack(alignment: .center){

			if !isCloud {
                Image(systemName:  item.status ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
					.scaleEffect(1.5)
					.symbolRenderingMode(.palette)
					.foregroundStyle( Color.primary, item.status ? .green : .red)
					.padding(.horizontal,5)
                    .if(item.status, transform: { view in
                        view
                            .symbolEffect(.variableColor, delay: 1)
                    })
                    .symbolEffect(.replace, delay: 2)
                    
                    
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
					HackerTextView(text: item.key, trigger: textAnimation)
						.lineLimit(1)
						.minimumScaleFactor(0.5)
                        .foregroundStyle(.foreground)
					Spacer()
				} .font(.system(size: 10))
				
			}
			Spacer()
			
            if isCloud{
                Image(systemName: "icloud.and.arrow.down")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .tint, Color.primary)
                    .symbolEffect(.bounce,delay: 1)
                    .onTapGesture {
                        complete()
                    }
            }else {
                
                
                Image(systemName: "doc.on.doc")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .tint, Color.primary)
                    .symbolEffect(.bounce,delay: 1)
                    .onTapGesture {
                        complete()
                        self.textAnimation.toggle()
                    }
            }
			
           
		}
	}
}
