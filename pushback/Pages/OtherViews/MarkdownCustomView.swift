//
//  MarkdownCustomView.swift
//  pushback
//
//  Created by lynn on 2025/3/26.
//

import SwiftUI
import Splash
import MarkdownUI


struct MarkdownCustomView:View {
    @Environment(\.colorScheme) var colorScheme
    
    var content:String
    var userInfo:String
    var searchText:String
    var showRaw:Bool
    var showCodeViewColor:Bool
   
    
    private var codeHighlightColorScheme: Splash.Theme {
        colorScheme == .dark ? .wwdc17(withFont: .init(size: 16)) : .sunset(withFont: .init(size: 16))
    }
    
    init( content: String, userInfo: String = "", searchText: String = "", showRaw: Bool = false, showCodeViewColor: Bool = false) {
        self.content = content
        self.userInfo = userInfo
        self.searchText = searchText
        self.showRaw = showRaw
        self.showCodeViewColor = showCodeViewColor
    }
   
    var body: some View {
        
        if showRaw || !searchText.isEmpty{
            MarkdownCustomView.highlightedText(searchText: searchText, text: searchText.isEmpty ? userInfo : content)
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
        }else {
            Markdown(content)
                .if(showCodeViewColor){view in
                    view
                        .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
                }
                .markdownTheme(MarkdownTheme.enchantedTheme)
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
        }
       
    }
    
    static func highlightedText(searchText: String, text: String) -> some View {
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
}

