//
//  MessageView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import RealmSwift


struct MessageView: View {
	
	@EnvironmentObject private var manager:PushbackManager
	@ObservedRealmObject var message:Message
    var searchText:String = ""
	@State var showRaw:Bool = false
	var showGroup:Bool =  false
    var body: some View {
		Section {
			
			HStack(alignment: .top){
				
				headView()
				
				
				VStack(alignment: .leading, spacing:5){
					
					
					if !showRaw{
						HStack{
							if let title = message.title{
								highlightedText(searchText: searchText, text: title)
									.font(.headline)
									.fontWeight(.bold)
									.textSelection(.enabled)
								
								
								Spacer()
							}
						}

						HStack{
							if let subtitle = message.subtitle{
								highlightedText(searchText: searchText, text: subtitle)
									.font(.subheadline)
									.fontWeight(.bold)
									.foregroundStyle(.gray)
									.textSelection(.enabled)


								Spacer()
							}
						}

						HStack{
							if let body = message.body{
								highlightedText(searchText: searchText, text: body)
									.font(.body)
									.textSelection(.enabled)
							}
							
							Spacer()
						}
						
					}else{
						highlightedText(searchText: searchText, text: message.userInfo)
							.font(.subheadline)
					}
					
				
				}
				.padding(10)
				.background(Color.whiteGary)
				.clipShape(RoundedRectangle(cornerRadius: 10))
				
				
			
				
			}
			
			
		}header: {
			HStack{
				Text(message.createDate.agoFormatString())
					.font(.caption2)
					.foregroundStyle(message.createDate.colorForDate())
				Spacer()
				
				if message.userInfo.count > 10{
					Text(showRaw ? "Close" : "Raw")
						.onTapGesture {
							self.showRaw.toggle()
						}
				}
				
			}
			
		}footer: {
			if showGroup{
				HStack{
					highlightedText(searchText: searchText, text: message.group)
						.textSelection(.enabled)
					Spacer()
				}
			}
		}
        
    }
	
	func highlightedText(searchText: String, text: String) -> some View {
		// 将搜索文本和目标文本都转换为小写
		let lowercasedSearchText = searchText.lowercased()
		let lowercasedText = text.lowercased()
		
		// 在小写版本中查找范围
		guard let range = lowercasedText.range(of: lowercasedSearchText) else {
			return Text(text)
		}
		
		// 计算原始文本中的索引
		let startIndex = text.distance(from: text.startIndex, to: range.lowerBound)
		let endIndex = text.distance(from: text.startIndex, to: range.upperBound)
		
		// 使用原始文本创建前缀、匹配文本和后缀
		let prefix = Text(text.prefix(startIndex))
		let highlighted = Text(text[text.index(text.startIndex, offsetBy: startIndex)..<text.index(text.startIndex, offsetBy: endIndex)]).bold().foregroundColor(.red)
		let suffix = Text(text.suffix(text.count - endIndex))
		
		// 返回组合的文本视图
		return prefix + highlighted + suffix
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
	
	
	@ViewBuilder
	func headView() -> some View{
		AvatarView(id: message.id.uuidString, icon: message.icon, mode: message.mode)
			.frame(width: 35, height: 35, alignment: .center)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.overlay(alignment: .topLeading) {
				if let _ =  message.url {
					Image(systemName: "link.circle")
						.symbolRenderingMode(.palette)
						.foregroundStyle(Color.primary, .green)
						.offset(x:-10 , y: -10)
				}
			}
			.padding(.top,10)
			
			.onTapGesture {
				if let url = message.url, let fileUrl = URL(string: url) {
					manager.openUrl(url: fileUrl)
				}
				
			}
	}
	
    
}


#Preview {
    
    List {
		MessageView(message: Message.messages.first!)
            .frame(width: 300)
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
			.environmentObject(PushbackManager.shared)
        
    }.listStyle(GroupedListStyle())
    
    
}
