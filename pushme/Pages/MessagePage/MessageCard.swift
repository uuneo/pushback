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
        guard let selectId = AppManager.shared.selectId else {
            return .clear
        }
        return selectId.uppercased() == message.id.uppercased() ? .orange : .clear
        
    }
    @State private var image:UIImage? = nil
    @State private var imageHeight:CGFloat = .zero
    @EnvironmentObject private var messageManager: MessagesManager
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
                        }
                        
                        if let url =  message.url{
                            HStack(spacing: 1){
                                Image(systemName: "network")
                                    .imageScale(.small)
                                    
                                MarkdownCustomView.highlightedText(searchText: searchText, text: url)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundStyle(.accent)
                        }
                    }
                    Spacer(minLength: 0)
                    if message.url != nil {
                        Image(systemName: "chevron.right")
                            .imageScale(.medium)
                            .foregroundStyle(.gray)
                    }
                }
                .contentShape(Rectangle())
                .if(message.url != nil){ view in
                    view
                        .VButton{ _ in
                            if let url = message.url, let fileUrl = URL(string: url){
                                AppManager.openUrl(url: fileUrl)
                                
                            }
                            return true
                        }
                }
                
                
                if message.title != nil || message.subtitle != nil || message.url != nil || showAvatar{
                    Line()
                        .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [5,3]))
                        .frame(height: 1)
                        .padding(.vertical,1)
                        .padding(.horizontal, 3)
                    
                }
                VStack{
                    if let uiImage = image{
                        GeometryReader { proxy in
                            
                            VStack{
                                
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                                    .onAppear{
                                        let size = uiImage.size
                                        let aspectRatio = size.height / size.width
                                        imageHeight = proxy.size.width * aspectRatio
                                    }
                                    .contextMenu{
                                        Button{
                                            if let image = image{
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
                                            }
                                        }label:{
                                            Label("保存图片", systemImage: "square.and.arrow.down.on.square")
                                        }
                                    }preview: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
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
                        .contentShape(Rectangle())
                        .VButton{ _ in
                            self.complete?()
                            return true
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
                        .onTapGesture(count: 2) {
                            self.complete?()
                            Haptic.impact(.light)
                        }
                    }
                }
                
               
            }
            .padding(8)
            .swipeActions(edge: .leading, allowsFullSwipe: true){
                Button{
                    Haptic.impact()
                    DispatchQueue.main.async{
                        AppManager.shared.askMessageId = message.id
                        AppManager.shared.router.append(.assistant)
                    }
                }label:{
                    Label("智能助手", systemImage: "atom")
                        .symbolEffect(.bounce, delay: 2)
                }.tint(.green)
            }
            .swipeActions(edge: .leading){
                Button{
                    Haptic.impact()
                    Task(priority: .high) {
                        guard let player = await AudioManager.shared.Speak(message.voiceText) else {
                            return
                        }
                        player.play()
                    }
                }label:{
                    Label("语音", systemImage: "speaker.wave.2.bubble.left")
                        .symbolEffect(.variableColor)
                   
                }.tint(.blue)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                        withAnimation(.default){
                            messageManager.singleMessages.removeAll(where: {$0.id == message.id})
                        }
                    }
                    
                    Task.detached(priority: .background){
                        _ = await DatabaseManager.shared.delete(message)
                    }
                } label: {
                    
                    Label( "删除", systemImage: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.primary)
                    
                }.tint(.red)
            }
            .overlay(alignment: .bottom) {
                UnevenRoundedRectangle(topLeadingRadius: 15, bottomLeadingRadius: 5, bottomTrailingRadius: 5, topTrailingRadius: 15,style: .continuous)
                    .fill(.gray.opacity(0.6))
                    .frame(height: 3)
                    .padding(.horizontal, 30)
            }
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.message)
                    .shadow(group: false)
            )
            .onAppear{
                Task(priority: .userInitiated) {
                    if let image = message.image,
                       let file = await ImageManager.downloadImage(image){
                        self.image = UIImage(contentsOfFile: file)
                        
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            
        }header: {
            MessageViewHeader()
                
            
        }footer: {
            
            HStack{
                if showGroup{
                    MarkdownCustomView.highlightedText(searchText: searchText, text: message.group)
                        .textSelection(.enabled)
                    
                }
                Spacer()
                
            }
            .padding(.horizontal,15)
            .padding(.top, 3)
            
            
        }
        
    }
    
    @ViewBuilder
    func MessageViewHeader()-> some View{
        HStack{
            
            Text(dateTime)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(AppManager.shared.selectId?.uppercased() == message.id.uppercased() ?
                    .white : message.createDate.colorForDate() )
                .padding(.leading, 10)
                .VButton(onRelease: { value in
                    withAnimation {
                        let number = self.timeMode + 1
                        self.timeMode = number > 2 ? 0 : number
                    }
                    return true
                })
            
            
            Spacer()
            
            HStack(spacing: 25){
               
                Image(systemName: "doc.on.clipboard")
                    .scaleEffect(0.9)
                    .VButton { _ in
                        if  let image = image {
                            Clipboard.set(message.search,[UTType.image.identifier: image])
                        }else{
                            Clipboard.set(message.search)
                        }
                        Toast.copy(title: "复制成功")
                        return true
                    }
                
                Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                    .scaleEffect(0.95)
                    .bold()
                    .padding(.trailing)
                    .symbolEffect(.wiggle, delay: 2)
                    .VButton { _ in
                        self.complete?()
                        return true
                    }
                    
            }
            .font(.title3)
            .symbolRenderingMode(.palette)
            .customForegroundStyle(.accent, .primary)
            
            
        }
        .background(linColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 15)
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
            .listRowInsets(EdgeInsets())
    }.listStyle(.grouped)
    
    
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
    func shadow(group: Bool) -> some View {
        self
            .shadow(color: Color.shadow2, radius: 1, x: -1, y: -1)
            .shadow(color: Color.shadow1, radius: 5, x: 3, y: 5)
    }
}
