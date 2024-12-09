//
//  HistoricalPictureView.swift
//  pushback
//
//  Created by He Cho on 2024/11/22.
//

import SwiftUI



struct HistoricalPictureView: View {

	@State private var show:Bool = false
	
	@State private var selectImage:AppIconEnum = .def
	@State private var text:String = ""
	
	var body: some View {
		ScrollView(.vertical, showsIndicators: false){
			LazyVGrid(columns:Array(repeating: .init(.flexible(), spacing: 10), count: 3 ),spacing: 20) {
				ForEach(AppIconEnum.allCases,id: \.self) {item  in
					Image(item.logo)
						.resizable()
						.scaledToFit()
						.frame(height: 100)
						.onTapGesture {
							selectImage = item
							show = true
							
						}
				}
			}
		}.searchable(text: $text)
    }
}

#Preview {
	NavigationStack{
		HistoricalPictureView()
	}
  
}
