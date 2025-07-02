//
//  MessageCardView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import Defaults
import AVFAudio
import UniformTypeIdentifiers

struct MessageCard: View {
   
    var message:Message
    var searchText:String = ""
    var showGroup:Bool =  false
    var showAllTTL:Bool = false
    var showAvatar:Bool = true
    var complete:(()->Void)? = nil
    
    @State private var showLoading:Bool = false
    
    @State private var timeMode:Int = 0
    
    var dateTime:String{
        if showAllTTL{
            message.expiredTime()
        }else{
            switch timeMode {
            case 1: message.createDate.formatString()
            case 2: message.expiredTime()
            default: message.createDate.agoFormatString()
            }
        }
    }
    
    
    var linColor:Color{
        
        if let selectId = AppManager.shared.selectId {
            let right = selectId.uppercased() == message.id.uppercased()
            return right ?  .accent : .clear
        }
        return .clear
        
    }
    @State private var image:UIImage? = nil
    @State private var imageHeight:CGFloat = .zero
    
    var body: some View {
        Section {
            
            
            VStack{
                HStack(alignment: .center){
                    if showAvatar{
                        
                        AvatarView( icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 5)
                            .overlay(alignment: .bottomTrailing) {
                                if message.level > 2{
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red)
                                }
                            }
                        
                    }
                    VStack{
                        if let title = message.title{
                            MarkdownCustomView.highlightedText(searchText: searchText, text: title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        
                        if let subtitle = message.subtitle{
                            MarkdownCustomView.highlightedText(searchText: searchText, text: subtitle)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            if let url =  message.url{
                                MarkdownCustomView.highlightedText(searchText: searchText, text: url)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if message.url != nil {
                        Image(systemName: "chevron.right")
                            .imageScale(.medium)
                            .foregroundStyle(.gray)
                    }
                }
                
                if message.title != nil || message.subtitle != nil || message.url != nil || showAvatar{
                    Line()
                        .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5,3]))
                        .frame(height: 1)
                        .padding(.vertical,1)
                        .padding(.horizontal, 3)
                        
                }
                if let uiImage = image{
                    GeometryReader { proxy in
                        
                        VStack{
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .customDraggable(200)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                                .onAppear{
                                    let size = uiImage.size
                                    let aspectRatio = size.height / size.width
                                    imageHeight = proxy.size.width * aspectRatio
                                }
                            
                            Line()
                                .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5,3]))
                                .frame(height: 1)
                                .padding(.vertical,1)
                                .padding(.horizontal, 3)
                        }
                    }
                    
                    .frame(height: imageHeight)
                    .clipShape(Rectangle())
                    .onTapGesture {
                        self.complete?()
                        Haptic.impact(.light)
                    }
                }
                
                if let body = message.body{
                    ScrollView(.vertical) {
                        MarkdownCustomView(content: body, searchText: searchText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 5)
                    }
                    .frame(maxHeight: 365)
                    .scrollIndicators(.hidden)
                    
                }
            }
            .VButton(release: 1)
            .onTapGesture {
                if let url = message.url, let fileUrl = URL(string: url){
                    AppManager.openUrl(url: fileUrl)
                    Haptic.impact(.light)
                }
            }
            .onTapGesture(count: 2) {
                self.complete?()
                Haptic.impact(.light)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.clear)
                    .frame(height: 5)
                    .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .contentShape(Rectangle())
            .contextMenu{
               
                Section{
                    Button{
                         DispatchQueue.main.async{
                            AppManager.shared.askMessageId = message.id
                            AppManager.shared.router.append(.assistant)
                        }
                        Haptic.impact(.light)
                    }label: {
                        Label("问智能助手", image: "chatgpt")
                    }
                }
               
                Section{
                    
                    Button{
                        if  let image = image {
                            Clipboard.set(message.search,[UTType.image.identifier: image])
                        }else{
                            Clipboard.set(message.search)
                        }
                        Toast.copy(title: "复制成功")
                        Haptic.impact(.light)
                    }label:{
                        Label("复制内容", systemImage: "doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green)
                    }
                    

                    
                    if let image = image{
                        Button {
                            
                            image.bat_save(intoAlbum: nil) { success, status in
                                if success{
                                    Toast.copy(title: "保存成功")
                                }else{
                                    Toast.question(title: "保存失败")
                                }
                            }
                            Haptic.impact(.light)
                        } label: {
                            Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.accent, .green)
                        }

                    }
                }
                

               
                Section{
                    
                    Button {
                        self.complete?()
                        Haptic.impact(.light)
                    } label: {
                        Label("全屏查看", systemImage: "arrow.up.left.arrow.down.right")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, .green)
                    }

                }
                
            }
            .onAppear{
                Task(priority: .userInitiated) {
                    if let image = message.image,
                       let file = await ImageManager.downloadImage(image){
                        self.image = UIImage(contentsOfFile: file)
                        
                    }
                }
            }
            .shadow()
//            .shadow(color: Color.shadow1, radius: 5, x: 5, y: 8)
//            .shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .padding(.vertical, 5)
            .padding(.bottom, 3)
            .padding(.horizontal, 20)
            
           
        }header: {
            MessageViewHeader()
                .padding(5)
                .background(linColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                
        }footer: {
            if showGroup{
                HStack{
                    MarkdownCustomView.highlightedText(searchText: searchText, text: message.group)
                        .textSelection(.enabled)
                    Spacer()
                }
            }
        }.listRowInsets(EdgeInsets())
        
    }
    @ViewBuilder
    func MessageViewHeader()-> some View{
        HStack(alignment: .bottom){
           
            Text(dateTime)
                .font(.caption2)
                .foregroundStyle(AppManager.shared.selectId?.uppercased() == message.id.uppercased() ?
                    .white : message.createDate.colorForDate() )
                .VButton(onRelease: { value in
                    withAnimation {
                        let number = self.timeMode + 1
                        self.timeMode = number > 2 ? 0 : number
                    }
                    return true
                })
                .padding(.leading, 10)
            
            Spacer()
        
        }
    }

    
    
    func limitTextToLines(_ text: String, charactersPerLine: Int) -> String {
        var result = ""
        var currentLineCount = 0
        
        for char in text {
            result.append(char)
            if char.isNewline || currentLineCount == charactersPerLine {
                result.append("\n")
                currentLineCount = 0
            } else {
                currentLineCount += 1
            }
        }
        
        return result
    }
    
}


#Preview {
    
    List {
        MessageCard(message: DatabaseManager.examples().first!)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .environmentObject(AppManager.shared)
        
    }.listStyle(GroupedListStyle())
    
    
}


struct Line: Shape{
    func path(in rect: CGRect) -> Path {
        return Path{path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            
        }
    }
    
}

extension View{
    func shadow(shadow: Color = Color.primary ) -> some View {
        self.shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 1, x: 1, y: 1)
            .shadow(color: Color.shadow1, radius: 5, x: 5, y: 8)
    }
}
