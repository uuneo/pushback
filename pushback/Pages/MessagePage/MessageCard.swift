//
//  MessageCardView.swift
//  pushback
//
//  Created by uuneo on 2025/2/13.
//

import SwiftUI
import RealmSwift
import Defaults


struct MessageCard: View {
    
    @ObservedRealmObject var message:Message
    var searchText:String = ""
    var showGroup:Bool =  false
    var showAllTTL:Bool = false
    var showAvatar:Bool = true
    var showAssistant:Bool = true
    var complete:(()->Void)? = nil
    @State private var showRaw:Bool = false
    @State private var showLoading:Bool = false
    @State private var showTTL:Bool = false
    
    @EnvironmentObject private var manager:PushbackManager
    
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
                        
                        AvatarView(id: message.id.uuidString, icon: message.icon)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        self.complete?()
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
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .onTapGesture(count: 2) {
                                self.complete?()
                            }
                    }
                    
                }
             
                
            }
            .frame(maxHeight: 300)
            .padding(.horizontal, 5)
            .background(Color.whiteGary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
           
           
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
           
                Menu {
                    if showAssistant{
                        Button{
                            PushbackManager.shared.sheetPage = .chatgpt(message.id.uuidString)
                            PushbackManager.vibration(style: .light)
                        }label: {
                            Label("问智能助手", image: "chatgpt")
                        }
                    }
                    
                    if let url = message.url, let fileUrl = URL(string: url){
                        
                        Button{
                            PushbackManager.openUrl(url: fileUrl)
                            PushbackManager.vibration(style: .light)
                        }label:{
                            Label("打开链接", systemImage: "airplane.departure")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary, .green)
                            
                        }
                    }
                    
                    Button{
                        
                        Clipboard.shared.setString(message.search)
                        Toast.copy(title: String(localized: "复制成功"))
                        PushbackManager.vibration(style: .light)
                    }label:{
                        Label("复制全部", systemImage: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary, .green)
                    }
                } label: {
                    
                    Image(systemName: showRaw ?  "captions.bubble.fill" : "captions.bubble" )
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.primary, .tint)
                        .symbolEffect(.replace)
                        .symbolEffect(.bounce,delay: 1)
                        .imageScale(.small)
                        .padding(.leading, 10)
                    
                }.foregroundStyle(.primary, .tint)
           
            
            
            Text((showTTL || showAllTTL) ? message.expiredTime() : message.createDate.agoFormatString())
                .font(.caption2)
                .foregroundStyle( (showTTL || showAllTTL) ? (message.ttl < 7 ? .red : .green) : message.createDate.colorForDate())
                .pressEvents(onRelease: { value in
                    withAnimation {
                        self.showTTL.toggle()
                    }
                })
            
            Spacer()
            
            if let url = message.url, let url = URL(string: url){
                Image(systemName: "airplane.departure")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .green)
                    .symbolEffect(.bounce,delay: 1)
                    .padding(.leading, 10)
                    .pressEvents(onRelease: { value in
                        PushbackManager.openUrl(url: url)
                    })
            }
            
            if showRaw{
                Image(systemName: "xmark.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, .green)
                    .pressEvents(onRelease:{ result in
                        self.showRaw.toggle()
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
        MessageCard(message: Message.examples().first!)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            .environmentObject(PushbackManager.shared)
        
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
