//
//  MarkdownCustomView.swift
//  pushback
//
//  Created by lynn on 2025/3/26.
//

import SwiftUI
import Splash
import MarkdownUI
import Kingfisher
import NetworkImage
import cmark_gfm
import cmark_gfm_extensions
import Foundation
import WebKit

private typealias UnsafeNode = UnsafeMutablePointer<cmark_node>

struct MarkdownCustomView:View {
    @Environment(\.colorScheme) var colorScheme
    
    var content:String
    var userInfo:String
    var searchText:String
    var showRaw:Bool
    var showCodeViewColor:Bool
    var scaleFactor: CGFloat
    
    private var codeHighlightColorScheme: Splash.Theme {
        colorScheme == .dark ? .wwdc17(withFont: .init(size: 16)) : .sunset(withFont: .init(size: 16))
    }
    
    init( content: String, userInfo: String = "", searchText: String = "", showRaw: Bool = false, showCodeViewColor: Bool = false, scaleFactor: CGFloat = 1.0) {
        self.content = content
        self.userInfo = userInfo
        self.searchText = searchText
        self.showRaw = showRaw
        self.showCodeViewColor = showCodeViewColor
        self.scaleFactor = scaleFactor
    }
    
    @ScaledMetric(relativeTo: .callout) var baseSize: CGFloat = 17
   
    var body: some View {
        
        if showRaw || !searchText.isEmpty{
            MarkdownCustomView.highlightedText(searchText: searchText, text: searchText.isEmpty ? userInfo : content)
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
        }else {
            
            Markdown(content)
                .environment(\.openURL, OpenURLAction { url in
                    print("用户点击的链接是：\(url)")
                    AppManager.openUrl(url: url)
                    return .handled // 表示链接已经被处理，不再执行默认行为
                })
                .if(showCodeViewColor){view in
                    view
                        .markdownCodeSyntaxHighlighter(.splash(theme: codeHighlightColorScheme))
                }
                .markdownTheme(MarkdownTheme.defaultTheme(baseSize, scaleFactor: scaleFactor))
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
