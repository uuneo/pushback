//
//  SelectMessageView.swift
//  pushback
//
//  Created by lynn on 2025/5/2.
//
import SwiftUI
import Kingfisher
import Defaults

enum SelectMessageViewMode:Int, Equatable{
    case translate
    case abstract
    case raw
}


struct SelectMessageView:View {
    var message:Message
    var dismiss:() -> Void
    @StateObject private var chatManager = openChatManager.shared
    @Default(.assistantAccouns) var assistantAccouns
    @Default(.translateLang) var translateLang
    
    @State private var scaleFactor: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    
    // 设定基础字体大小
    @ScaledMetric(relativeTo: .body) var baseTitleSize: CGFloat = 17
    @ScaledMetric(relativeTo: .subheadline) var baseSubtitleSize: CGFloat = 15
    @ScaledMetric(relativeTo: .footnote) var basedateSize: CGFloat = 13
    
    
    @StateObject private var manager = AppManager.shared
    
    @State private var image:UIImage? = nil
    @State var scale : CGFloat = 1
    
    @State private var isDismiss:Bool = false
    @State private var messageShowMode:SelectMessageViewMode = .raw
    
    @State private var translateResult:String = ""
    @State private var abstractResult:String = ""
    
    @State private var showAssistantSetting:Bool = false
    
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
                                                if status == .authorized || status == .limited{
                                                    if success{
                                                        Toast.success(title: "保存成功")
                                                    }else{
                                                        Toast.question(title: "保存失败")
                                                    }
                                                }else{
                                                    Toast.error(title: "没有相册权限")
                                                }
                                                
                                            }
                                        } label: {
                                            Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                                .symbolRenderingMode(.palette)
                                                .customForegroundStyle(.accent, .primary)
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
                        
                        
                        if messageShowMode == .abstract{
                            VStack{
                                
                                AbstractMessageView(message: message, scaleFactor: scaleFactor,lang: translateLang.name, abstractResult: $abstractResult)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay {
                                ColoredBorder(cornerRadius: 15)
                            }
                            
                        }
                               
                        
                        if messageShowMode == .translate{
                            
                            TranslateMesssageView(message: message, scaleFactor: scaleFactor,lang: translateLang.name, translateResult: $translateResult)
                            
                        }else{
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
                                    Spacer(minLength: 0)
                                }
                            }
                            
                            Line()
                                .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5, 3]))
                                .padding(.horizontal, 3)
                            
                            if let body = message.body{
                                HStack{
                                    MarkdownCustomView(content: body, searchText: "", scaleFactor: scaleFactor)
                                        .textSelection(.enabled)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .gesture(
                        MagnificationGesture()
                            .onChanged({ value in
                                let delta = value / lastScaleValue
                                lastScaleValue = value
                                scaleFactor *= delta
                                scaleFactor = min(max(scaleFactor, 1.0), 3.0) // 限制最小/最大缩放倍数
                            })
                            .onEnded{ _ in
                                lastScaleValue = 1.0
                            }
                    )
                    
                    
                    
                }
                .frame(width: windowWidth)
                .onAppear{
                    Task(priority: .userInitiated) {
                        if let image = message.image,
                           let file =  await ImageManager.downloadImage(image) {
                            self.image = UIImage(contentsOfFile: file)
                        }
                    }
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global).minY) { newY in
                            if newY > 100 && !isDismiss {
                                self.isDismiss = true
                                Haptic.impact()
                                self.dismiss()
                            }
                        }
                       
                })
                
            }
            .overlay(alignment: .topTrailing, content: {
                HStack{
                   
                    
                    Picker("Select Language", selection: $translateLang) {
                        ForEach(Multilingual.commonLanguages, id: \.id) { country in
                            
                            Text("\(country.flag)  \(country.name)")
                            .tag(country)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        withAnimation(.spring()){
                            self.dismiss()
                        }
                        Haptic.impact(.light)
                    }) {
                        
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(.ultraThickMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top,  UIApplication.shared.topSafeAreaHeight )
            })
            .scaleEffect(scale)
            .background(
                ZStack(alignment: .top){
                    Rectangle()
                        .fill(.background)
                        
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .blur(radius: 20)
                            .scaleEffect(x: 2)
                    }
                }.ignoresSafeArea()
               
            )
            .safeAreaInset(edge: .bottom, alignment: .leading){
                HStack{
                    
                    Button{
                        
                        Task(priority: .userInitiated) {
                            
                            var text:String = ""
                            switch messageShowMode {
                            case .translate:
                                text = PBMarkdown.plain(translateResult)
                            case .abstract:
                                text = abstractResult
                            case .raw:
                                text = message.voiceText
                            }
                            guard !text.isEmpty else { return }
                            guard let player = await AudioManager.shared.Speak(text) else {
                                return
                            }
                            player.play()
                        }
                    }label:{
                        ZStack{
                            
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                            
                        }.frame(width: 80)
                        
                        
                    }
                    if messageShowMode == .translate{
                        Button{
                            self.messageShowMode = .raw
                            Haptic.impact()
                            
                        }label: {
                            Label(  "隐藏", systemImage: "eye.slash")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.accentColor, Color.primary)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                    }else{
                        Button{
                            self.messageShowMode = .translate
                            Haptic.impact()
                            if assistantAccouns.first(where: {$0.current}) == nil{
                                self.showAssistantSetting.toggle()
                            }
                        }label:{
                            Label( "翻译" , systemImage:  "translate")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.accentColor, Color.primary)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                        }
                    }
                    
                    Button{
                        self.messageShowMode = (self.messageShowMode == .abstract) ?  .raw : .abstract
                        Haptic.impact()
                        if assistantAccouns.first(where: {$0.current}) == nil && messageShowMode == .abstract{
                            self.showAssistantSetting.toggle()
                        }
                    }label: {
                        Label(messageShowMode == .abstract ?  "隐藏"  : "总结",
                              systemImage: messageShowMode == .abstract ? "eye.slash" : "doc.text.magnifyingglass")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                }
                .padding(.bottom)
                .padding(.top)
                .background(.background)
                
            }
            .animation(.spring(), value: messageShowMode)
            .onAppear{
                self.hideKeyboard()
            }
            .onDisappear{
                chatManager.cancellableRequest?.cancelRequest()
            }
            .sheet(isPresented: $showAssistantSetting) {
                NavigationStack{
                    AssistantSettingsView()
                }
            }
        
    }
    
    
    
}


