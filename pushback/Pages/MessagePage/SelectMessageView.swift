//
//  SelectMessageView.swift
//  pushback
//
//  Created by lynn on 2025/5/2.
//
import SwiftUI
import Kingfisher

struct SelectMessageView:View {
    var message:Message
    var dismiss:() -> Void
    @State private var scaleFactor: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    // 设定基础字体大小
    @ScaledMetric(relativeTo: .body) var baseTitleSize: CGFloat = 17
    @ScaledMetric(relativeTo: .subheadline) var baseSubtitleSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) var basedateSize: CGFloat = 13
    

    
    var body: some View {
        ScrollView{
            
            ZStack{
                
                VStack{
                    
                    if let image = message.image{
                        VStack{
                            KFImage.url(URL(string: image))
                                .resizable()
                                .scaledToFit()
                                .zoomable()
                        }
                        .padding()
                        .zIndex(1)
                    }
                    
                    VStack{
                        HStack{
                            
                            VStack(alignment: .leading, spacing: 5){
                                Text(message.createDate.formatString())
                                if let host = message.host{
                                    Text(host.removeHTTPPrefix())
                                }
                            }
                            .font(.system(size: basedateSize * scaleFactor))
                            .foregroundStyle(.gray)
                            
                            Spacer()
                        }
                        .padding(.vertical)
                        
                        HStack{
                            Spacer(minLength: 0)
                            Text(message.title ?? "")
                                .font(.system(size: baseTitleSize * scaleFactor))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                        
                        HStack{
                            Spacer(minLength: 0)
                            Text(message.subtitle ?? "")
                                .font(.system(size: baseSubtitleSize * scaleFactor))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                        
                        Line()
                            .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
                            .frame(height: 1)
                            .padding(.horizontal, 5)
                        
                        HStack{
                            MarkdownCustomView(content: message.body ?? "", searchText: "", showCodeViewColor: false,scaleFactor: scaleFactor)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged({ value in
                                    let delta = value / lastScaleValue
                                    lastScaleValue = value
                                    scaleFactor *= delta
                                    scaleFactor = min(max(scaleFactor, 1.0), 3.0) // 限制最小/最大缩放倍数
                                })
                                .onEnded{ _ in
                                    lastScaleValue = 1.0
                                },
                            TapGesture(count: 2)
                                .onEnded{ _ in
                                    withAnimation {
                                        scaleFactor = scaleFactor == 1.0 ? 3.0 : 1.0
                                    }
                                }
                        )
                    )
                }
                .frame(width: UIScreen.main.bounds.width - 50)
            }
            .frame(width: UIScreen.main.bounds.width)
            .padding(.vertical, 50)
            .frame(minHeight: UIScreen.main.bounds.height - 100)
            
        }
        
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(
            Group{
                if scaleFactor >= 3.0{
                    Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                        .resizable()
                    
                }else{
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                        .resizable()
                }
            }
                .scaledToFit()
                .frame(width: 300)
                .foregroundStyle(.gray.opacity(0.1))
        )
        .background(.ultraThinMaterial)
        .containerShape(RoundedRectangle(cornerRadius: 0))
        .onTapGesture {
            dismiss()
        }
        .transition(.move(edge: .leading))
    }
}

