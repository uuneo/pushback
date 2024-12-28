//
//  MessageView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import RealmSwift


enum messageCompleteMode{
	case image
	case text
	case userInfo
}

struct MessageView: View {
	
	@EnvironmentObject private var manager:PushbackManager
	@ObservedRealmObject var message:Message
    var searchText:String = ""
	@State var showRaw:Bool = false
	var showGroup:Bool =  false
	var complete:((messageCompleteMode)->Void)? = nil
	@State private var showLoading:Bool = false
    var body: some View {
		Section {
				VStack(alignment: .leading, spacing:5){

					HStack(alignment: .center){
						AvatarView(id: message.id.uuidString, icon: message.icon, mode: message.mode)
							.frame(width: 30, height: 30, alignment: .center)
							.clipShape(RoundedRectangle(cornerRadius: 10))
							.saturation(showRaw ? 0 : 1)
							.onTapGesture{
								self.showRaw.toggle()
							}


						VStack{
							if let title = message.title{
								HStack{
									highlightedText(searchText: searchText, text: title)
										.font(.headline)
										.fontWeight(.bold)
										.textSelection(.enabled)

									Spacer()

								}
								.contentShape(Rectangle())
								.onTapGesture(count: 2) {
									self.complete?(.text)
								}
							}


							if let subtitle = message.subtitle{


								HStack{

									highlightedText(searchText: searchText, text: subtitle)
										.font(.subheadline)
										.fontWeight(.bold)
										.foregroundStyle(.gray)
										.textSelection(.enabled)
										

									Spacer()
								}
								.contentShape(Rectangle())
								.onTapGesture(count: 2) {
									self.complete?(.text)
								}


							}
						}

					}

					Line()
						.stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
						.frame(height: 1)
						.padding(.horizontal, 5)

					
					if !showRaw{
						HStack{
							if let body = message.body{
								highlightedText(searchText: searchText, text: body)
									.font(.body)
									.textSelection(.enabled)
									.transition(.opacity)

							}
							
							Spacer()
						}
						.contentShape(Rectangle())
						.onTapGesture(count: 2) {
							self.complete?(.text)
						}


					}else{
						highlightedText(searchText: searchText, text: message.userInfo)
							.transition(.opacity)
							.font(.subheadline)
							.onTapGesture(count: 2) {
								self.complete?(.userInfo)
							}

					}
					
				
				}
				.padding(10)
				.background(Color.whiteGary)
				.clipShape(RoundedRectangle(cornerRadius: 10))

		}header: {
			HStack(alignment: .bottom){



				Text(message.createDate.agoFormatString())
					.font(.caption2)
					.foregroundStyle(message.createDate.colorForDate())
					.padding(.leading, 10)
				Spacer()

				if let _ =  message.url {

					Image(systemName: "link.circle")
						.resizable()
						.symbolRenderingMode(.palette)
						.foregroundStyle(Color.primary, .green)
						.frame(width: 20, height: 20, alignment: .center)
						.padding(.horizontal, 10)

						.onTapGesture {
							if let url = message.url, let fileUrl = URL(string: url) {
								manager.openUrl(url: fileUrl)
							}
						}
				}

				Group{
					if message.image.count == 1  {
						Image(systemName: "photo.circle")
							.resizable()
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint, .primary)


					}else if message.image.count > 1  {
						Image(systemName: "photo.on.rectangle.angled")
							.resizable()
							.symbolRenderingMode(.palette)
							.foregroundStyle(.tint, .primary)
					}
				}
				.frame(width: 20, height: 20, alignment: .center)
				.padding(.horizontal, 10)
				.overlay{
					if showLoading{
						ProgressView()
							.progressViewStyle(CircularProgressViewStyle())
							.transition(.opacity)
							.background(.ultraThinMaterial)
					}
				}
				.onTapGesture {
					self.showLoading = true
					self.complete?(.image)
					self.showLoading = false
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
		}.listRowInsets(EdgeInsets())

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

    
}


#Preview {
    
    List {
		MessageView(message: Message.messages.first!)
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
