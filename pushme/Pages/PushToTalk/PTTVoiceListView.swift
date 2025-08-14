//
//  PTTVoiceListView.swift
//  pushme
//
//  Created by lynn on 2025/7/28.
//

import SwiftUI


struct PTTVoiceListView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack{
            HStack(spacing: 0){
                Text("消息列表")
                    .font(.title3)
                Spacer(minLength: 0)
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .padding(5)
                    .VButton { _ in
                        self.dismiss()
                        return true
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.background)
            
            List{
                
                VoiceCard()
                
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                
            }
            .listStyle(.grouped)
            
        }.environment(\.colorScheme, .dark)
    }
}

struct VoiceCard: View {
    @State var pregress = 0.1
    var body: some View {
        Section{
            GeometryReader {
                let size = $0.size
                HStack{
                    Image(systemName: "dot.radiowaves.right")
                        .font(.title)
                        .symbolEffect(.variableColor)
                        .padding(.horizontal, 15)
                    Text("12″")
                        .font(.title3)
                    Spacer()
                    
                }
                .fontWeight(.black)
                .frame(height: size.height)
                .frame(width: size.width * 0.5)
                
                .background(
                    GeometryReader {
                        let size = $0.size
                        ZStack(alignment: .leading){
                            Rectangle()
                                .fill(Color.gray.opacity(0.9))
                            
                            Rectangle()
                                .fill(Color.accent)
                                .frame(width: size.width * pregress)
                        }.clipShape(
                            RoundedRectangle(cornerRadius: 20)
                        )
                    }
                )
                .animation(.default, value: pregress)
                .VButton { _ in
                    pregress = Double.random(in: 0...1)
                    
                    return true
                }
            }
            .frame(height: 50)
            .padding(.horizontal)
        }header: {
            HStack{
                Text(Date().formatted())
                    .foregroundStyle(.gray)
                    .font(.headline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 25)
            .padding(.top, 10)
        }
        
        
    }
}


#Preview {
    PushToTalkView()
}
