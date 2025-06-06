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
    
    
    @StateObject private var manager = AppManager.shared
    
    @State private var image:UIImage? = nil
    @State var scale : CGFloat = 1
    
    var body: some View {
        ScrollView{
            
     
            
            VStack{
                VStack{
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                            .zoomable()
                            .contextMenu{
                                Section {
                                    Button {
                                
                                        image.bat_save(intoAlbum: nil) { success, status in
                                            if success{
                                                Toast.copy(title: "保存成功")
                                            }else{
                                                Toast.question(title: "保存失败")
                                            }
                                        }
                                    } label: {
                                        Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(Color.accent, .green)
                                    }
                                }
                            }
                            
                    }
                }
                .padding(.top, UIApplication.shared.topSafeAreaHeight)
                .zIndex(1)
   

                VStack{
                    HStack{
                        
                        VStack(alignment: .leading, spacing: 5){
                            Text(message.createDate.formatString())
                            if let host = message.host{
                                Text(host.removeHTTPPrefix())
                            }
                        }
                        .font(.system(size: basedateSize * scaleFactor))
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    if let title = message.title{
                        HStack{
                            Spacer(minLength: 0)
                            Text(title)
                                .font(.system(size: baseTitleSize * scaleFactor))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                    
                   
                    if let subtitle = message.subtitle{
                        HStack{
                            Spacer(minLength: 0)
                            Text(subtitle)
                                .font(.system(size: baseSubtitleSize * scaleFactor))
                                .fontWeight(.bold)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                   
                    
                    Line()
                        .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
                        .frame(height: 1)
                        .padding(.horizontal, 5)
                    
                    if let body = message.body{
                        HStack{
                            MarkdownCustomView(content: body, searchText: "", showCodeViewColor: false,scaleFactor: scaleFactor)
                                .textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                
                }
                .padding()
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
                                Haptic.impact(.light)
                            }
                    )
                )
                
            }
            .frame(width: UIScreen.main.bounds.width)
            .onAppear{
                Task(priority: .userInitiated) {
                    if let image = message.image,
                       let file =  await ImageManager.downloadImage(image) {
                        self.image = UIImage(contentsOfFile: file)
                    }
                }
            }
            
        }
        .overlay(alignment: .topTrailing, content: {
            HStack{
                
                Spacer(minLength: 0)
                
                Button(action: {
                    withAnimation(.spring()){
                        self.dismiss()
                    }
                    Haptic.impact(.light)
                }) {
                    
                    Image(systemName: "xmark")
                        .foregroundColor(Color.black.opacity(0.7))
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top,  UIApplication.shared.topSafeAreaHeight )
        })
        .scaleEffect(scale)
        .ignoresSafeArea()
        .background(.ultraThinMaterial)
        .onAppear{
            self.hideKeyboard()
        }
    }
    

}


