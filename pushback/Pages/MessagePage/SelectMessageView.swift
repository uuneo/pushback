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
    
    @State private var image:Image? = nil
    @State var scale : CGFloat = 1
    
    var body: some View {
        ScrollView{
            
     
            
            VStack{
                
                GeometryReader{reader in
                    
                    ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
                        
                        if let image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .addPinchZoom()
                                .draggable( image) {
                                    // 拖动时的预览图
                                    image
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                }
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 2.5)
                        }
                        
                     
                           
                    }
                        .offset(y: (reader.frame(in: .global).minY > 0 && scale == 1) ? -reader.frame(in: .global).minY : 0)
                    // Gesture For Closing Detail View....
                    .gesture(DragGesture(minimumDistance: 0).onChanged(onChanged(value:)).onEnded(onEnded(value:)))
                }
                .frame(width: UIScreen.main.bounds.width, height: image == nil ? UIApplication.shared.windows.first!.safeAreaInsets.top + 10 :  UIScreen.main.bounds.height / 2.5)
                
            
                
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
                            }
                    )
                )
                
            }
            
            .frame(width: UIScreen.main.bounds.width)
            .onAppear{
                Task(priority: .userInitiated) {
                    if let image = message.image,
                       let file =  await ImageManager.downloadImage(image),
                       let uiImage = UIImage(contentsOfFile: file){
                        self.image = Image(uiImage: uiImage)
                        
                    }
                }
            }
            
        }
        .overlay(alignment: .topTrailing, content: {
            HStack{
                
                Spacer(minLength: 0)
                
                Button(action: {
                    withAnimation(.spring()){
                        manager.selectMessage = nil
                    }
                }) {
                    
                    Image(systemName: "xmark")
                        .foregroundColor(Color.black.opacity(0.7))
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, UIApplication.shared.windows.first!.safeAreaInsets.top + 10 )
        })
        .scaleEffect(scale)
        .ignoresSafeArea(.all, edges: .top)
        .background(.ultraThinMaterial.opacity(manager.selectMessage != nil ? 1 : 0.2))
        .transition(.scale(scale: 0, anchor: calculatePosition(manager.selectPoint)))
    }
    
    func calculatePosition(_ tapLocation:CGPoint) -> UnitPoint{
        UnitPoint(
            x: 0.5,
            y: tapLocation.y / UIScreen.main.bounds.height
        )
    }
    
    
    func onChanged(value: DragGesture.Value){
        
        // calculating scale value by total height...
        
        let scale = value.translation.height / UIScreen.main.bounds.height
        
        // if scale is 0.1 means the actual scale will be 1- 0.1 => 0.9
        // limiting scale value...
        
        if 1 - scale > 0.75{
            self.scale = 1 - scale
        }
    }
    
    func onEnded(value: DragGesture.Value){
        
        withAnimation(.spring()){
            
            // closing detail view when scale is less than 0.9...
            if scale < 0.9{
                AppManager.shared.selectMessage = nil
            }
            scale = 1
        }
    }
}

