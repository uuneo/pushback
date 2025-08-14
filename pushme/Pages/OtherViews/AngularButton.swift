//
//  AngularButton.swift
//  pushback
//
//  Created by uuneo 2024/10/13.
//

import SwiftUI


struct AngularButton: View {
	var title:String
	var disable:Bool = false
	var loading:String = ""
    var backgroundColor: AnyGradient = Color.pink.gradient
	var onTap:()->Void
   
	
	@State private var ispress = false
	
	var body: some View {
		
		HStack{
			
			Spacer()
			Text(loading != "" ? loading : title)
				.fontWeight(.semibold)
				.frame(maxWidth: .infinity, maxHeight: 50)
				.animation(.easeInOut,value: loading)
				.animation(.easeInOut,value: disable)
				.frame(height: 50)
                .foregroundStyle(disable ? .gray : .white)
				.background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill( backgroundColor)
                        .opacity(disable ? 0.3 : 1)
                )
               
				.VButton { _ in
					if !disable && loading == "" {
						self.ispress = true
					}
				  
				} onRelease: { res in
                    if !disable && loading == "" {
                        self.ispress = false
                    }
                    
                    if !disable && loading == "" && abs(res.translation.width) < 10 {
                        
                        onTap()
					}
                    return !disable && loading == ""
				}
			Spacer()
		}
		
	   
	}
	

}
