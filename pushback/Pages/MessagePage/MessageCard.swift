//
//  MessageCardView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults
import AVFAudio
import UniformTypeIdentifiers


struct MessageCard: View {
   
    @ObservedRealmObject var message:Message
    var searchText:String = ""
    var showGroup:Bool =  false
    var showAllTTL:Bool = false
    var showAvatar:Bool = true
    var complete:(()->Void)? = nil
    @State private var showRaw:Bool = false
    @State private var showLoading:Bool = false
    
    @State private var timeMode:Int = 0
    
    var dateTime:String{
        showAllTTL ?  message.expiredTime() :
        (timeMode == 1 ? message.createDate.formatString() : message.createDate.agoFormatString())
    }
    
    @EnvironmentObject private var manager:AppManager
    @EnvironmentObject private var chatManager:openChatManager
    
    var linColor:Color{
        
        if let selectId = manager.selectId {
            let right = selectId.uppercased() == message.id.uuidString
            return right ?  .red : .clear
        }
        return .clear
        
    }
    
    var body: some View {
        Section {
            
            
            VStack(alignment: .leading, spacing: 0){
                
                HStack(alignment: .center){
                    if showAvatar{
                        
                        AvatarView( icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top,5)
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
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.vertical, 5)
                                
                        }
                        
                        
                        if let subtitle = message.subtitle{
                            
                            HStack{
                                MarkdownCustomView.highlightedText(searchText: searchText, text: subtitle)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                if message.title != nil || message.subtitle != nil{
                    Line()
                        .stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
                        .frame(height: 1)
                        .padding(.horizontal, 5)
                        .padding(.vertical,3)
                }
               
                if let body = message.body{
                    ScrollView{
                        
                        MarkdownCustomView(content: body, userInfo: message.search, searchText: searchText,showRaw: showRaw)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            
                    }
                    
                }
             
                
            }
            .frame(maxHeight: 300)
            .padding(.horizontal, 5)
            .background(
                Color.whiteGary
                    .overlay(alignment: .topTrailing){
                        if let _ = message.image{
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .rotationEffect(.degrees(45))
                                .foregroundStyle(.gray.opacity(0.3))
                                .frame(maxHeight: 50)
                        }
                    }
            )
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.clear)
                    .frame(height: 5)
                    .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                self.complete?()
            }
            .contextMenu{
               
                Section{
                    Button{
                        chatManager.messageId = message.id.uuidString
                        manager.router.append(.assistant)
                        AppManager.vibration(style: .light)
                    }label: {
                        Label("问智能助手", image: "chatgpt")
                    }
                }
               
                Section{
                    if let body = message.body{
                        Button{
                            Clipboard.set(body)
                            Toast.copy(title: "复制成功")
                            AppManager.vibration(style: .light)
                        }label:{
                            Label("复制内容", systemImage: "doc")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green)
                        }
                        
                    }
                   
                    Button{
                        Task{
                            if let url = message.image,
                               let imageUrl = await ImageManager.downloadImage(url),
                               let image = UIImage(contentsOfFile: imageUrl)
                            {
                                Clipboard.set(message.search,[UTType.image.identifier: image])
                            }else{
                                Clipboard.set(message.search)
                            }
                            Toast.copy(title: "复制成功")
                            AppManager.vibration(style: .light)
                        }
                    }label:{
                        Label("复制全部", systemImage: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.accent, .green)
                    }
                }
                
                
                Section{
                    Button {
                        Task(priority: .high) {
                            guard let player = await AudioManager.shared.Speak(message.voiceText) else {
                                return
                            }
                            player.play()
                        }
                    }label: {
                        Label("朗读内容",  systemImage: "waveform")
                            .symbolEffect(.variableColor)
                    }
                }
               
                Section{
                    
                    if let url = message.url, let fileUrl = URL(string: url){
                        
                        Button{
                            AppManager.openUrl(url: fileUrl)
                            AppManager.vibration(style: .light)
                        }label:{
                            Label("打开链接", systemImage: "airplane.departure")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.accent, .green)
                            
                        }
                    }
                    
                    Button {
                        self.complete?()
                        AppManager.vibration(style: .light)
                    } label: {
                        Label("全屏查看", systemImage: "arrow.up.left.arrow.down.right")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.green, .green)
                    }

                }
                
            }
           
           
        }header: {
            MessageViewHeader()
                .padding(5)
                .background(linColor)
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
                .foregroundStyle( message.createDate.colorForDate() )
                .pressEvents(onRelease: { value in
                    withAnimation {
                        let number = self.timeMode + 1
                        self.timeMode = number > 2 ? 0 : number
                    }
                    return true
                })
                .padding(.leading, 10)
            
            Spacer()
            
            if let url = message.url, let url = URL(string: url){
                Image(systemName: "airplane.departure")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .green)
                    .symbolEffect(.bounce,delay: 1)
                    .padding(.leading, 10)
                    .pressEvents(onRelease: { value in
                        AppManager.openUrl(url: url)
                        return true
                    })
            }
            
            if showRaw{
                Image(systemName: "xmark.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, .green)
                    .pressEvents(onRelease:{ result in
                        self.showRaw.toggle()
                        return true
                    })
            }
           
        
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
        MessageCard(message: RealmManager.examples().first!)
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
