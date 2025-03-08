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
	var onTap:()->Void
   
	
	@State private var ispress = false
	
	var body: some View {
		
		HStack{
			
			Spacer()
			Text(loading != "" ? loading : title)
				.fontWeight(.semibold)
				.frame(maxWidth: .infinity, maxHeight: 50)
				.background(
					ZStack {
						
						if !disable{
							angularGradient
						}
						LinearGradient(gradient: Gradient(colors: [Color(.systemBackground).opacity(1), Color(.systemBackground).opacity(0.6)]), startPoint: .top, endPoint: .bottom)
							.cornerRadius(20)
							.blendMode(.softLight)
					}
				)
				.animation(.easeInOut,value: loading)
				.animation(.easeInOut,value: disable)
				.animation(.easeInOut,value: ispress)
				.frame(height: 50)
				.foregroundStyle(disable ? .gray : .primary)
				.foregroundStyle(loading == "" ? .primary : Color.red)
				.background( angularGradient)
				.scaleEffect(ispress ? 0.9 : 1)
				.opacity(ispress ? 0.6 : 1)
				.onTapGesture {
					if !disable && loading == "" {
						onTap()
					}
				}
				.pressEvents {
					if !disable && loading == "" {
						self.ispress = true
					}
				  
				} onRelease: {
					
					if !disable && loading == "" {
						self.ispress = false
					}
				}
			Spacer()
		}
		
	   
	}
	
	var angularGradient: some View {
		RoundedRectangle(cornerRadius: 20)
			.fill(.clear)
			.overlay(AngularGradient(
				gradient: Gradient(stops: [
					.init(color: Color(#colorLiteral(red: 0, green: 0.5199999809265137, blue: 1, alpha: 1)), location: 0.0),
					.init(color: Color(#colorLiteral(red: 0.2156862745, green: 1, blue: 0.8588235294, alpha: 1)), location: 0.4),
					.init(color: Color(#colorLiteral(red: 1, green: 0.4196078431, blue: 0.4196078431, alpha: 1)), location: 0.5),
					.init(color: Color(#colorLiteral(red: 1, green: 0.1843137255, blue: 0.6745098039, alpha: 1)), location: 0.8)]),
				center: .center
			))
			.padding(6)
			.blur(radius: 20)
	}

}
