//
//  MarkdownColors.swift
//  DeepSeek
//
//  Created by Harlans on 2024/12/3.
//

import SwiftUI
import MarkdownUI

struct MarkdownColors {
    // 主文本颜色
    static let text = Color(light: Color(rgba: 0x1A1A1AFF), dark: Color(rgba: 0xE0E0E0FF))
    
    // 次要文本颜色
    static let secondaryText = Color(light: Color(rgba: 0x4A4A4AFF), dark: Color(rgba: 0xA0A0A0FF))
    
    // 第三级文本颜色
    static let tertiaryText = Color(light: Color(rgba: 0x6B6B6BFF), dark: Color(rgba: 0x808080FF))
    
    // 背景颜色
    static let background = Color(light: .white, dark: Color(rgba: 0x121212FF))
    
    // 次要背景颜色
    static let secondaryBackground = Color(light: Color(rgba: 0xF5F5F5FF), dark: Color(rgba: 0x1E1E1EFF))
    
    // 链接颜色
    static let link = Color(light: Color(rgba: 0x1A73E8FF), dark: Color(rgba: 0x8AB4F8FF))
    
    // 边框颜色
    static let border = Color(light: Color(rgba: 0xDDDDDDFF), dark: Color(rgba: 0x888888FF))
    
    // 分割线颜色
    static let divider = Color(light: Color(rgba: 0xCCCCCCFF), dark: Color(rgba: 0x2D2D2DFF))
    
    // 复选框颜色
    static let checkbox = Color(rgba: 0x757575FF)
    
    // 复选框背景颜色
    static let checkboxBackground = Color(rgba: 0xEEEEEEFF)
}

extension View {
    func markdownHeadingStyle(fontSize: CGFloat, fontWeight: Font.Weight = .semibold) -> some View {
        self
            .relativeLineSpacing(.em(0.125))
            .markdownMargin(top: 24, bottom: 16)
            .markdownTextStyle {
                FontWeight(fontWeight)
                FontSize(.em(fontSize))
            }
    }
    
    func markdownParagraphStyle() -> some View {
        self
            .fixedSize(horizontal: false, vertical: true)
            .relativeLineSpacing(.em(0.25))
            .markdownMargin(top: 0, bottom: 16)
    }
}

struct MarkdownTheme {
    static func defaultTheme(_ defaultSize:CGFloat = 16, scaleFactor:CGFloat = 1.0) -> Theme {
        Theme()
            .text { FontSize(defaultSize * scaleFactor) }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(MarkdownColors.secondaryBackground)
                    
            }
            .strong { FontWeight(.semibold) }
            .link { ForegroundColor(MarkdownColors.link) }
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .markdownHeadingStyle(fontSize: 2)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading2 { configuration in
                VStack(alignment: .leading, spacing: 0) {
                    configuration.label
                        .relativePadding(.bottom, length: .em(0.3))
                        .markdownHeadingStyle(fontSize: 1.5)
                    Divider().overlay(MarkdownColors.divider)
                }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 1.25)
            }
            .heading4 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 1)
            }
            .heading5 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.875)
            }
            .heading6 { configuration in
                configuration.label
                    .markdownHeadingStyle(fontSize: 0.85)
                    .markdownTextStyle {
                        ForegroundColor(MarkdownColors.tertiaryText)
                    }
            }
            .paragraph { configuration in
                configuration.label
                    .markdownParagraphStyle()
            }
            .blockquote { configuration in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MarkdownColors.border)
                        .relativeFrame(width: .em(0.2))
                    configuration.label
                        .markdownTextStyle { ForegroundColor(MarkdownColors.secondaryText) }
                        .relativePadding(.horizontal, length: .em(1))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .codeBlock { configuration in
                CodeBlock(configuration)
            }
            .listItem { configuration in
                configuration.label
                    .padding(.bottom, 10)
            }
            .taskListMarker { configuration in
                Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(MarkdownColors.checkbox, MarkdownColors.checkboxBackground)
                    .imageScale(.small)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: MarkdownColors.border))
                    .markdownTableBackgroundStyle(
                        .alternatingRows(MarkdownColors.background, MarkdownColors.secondaryBackground)
                    )
                    .markdownMargin(top: 0, bottom: 16)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 {
                            FontWeight(.semibold)
                        }
                        BackgroundColor(nil)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 13)
                    .relativeLineSpacing(.em(0.25))
            }
            .thematicBreak {
                Divider()
                    .relativeFrame(height: .em(0.25))
                    .overlay(MarkdownColors.border)
                    .markdownMargin(top: 24, bottom: 24)
            }
            
            
    }
}

struct CodeBlock: View {
    var configuration: CodeBlockConfiguration
    
    init(_ configuration: CodeBlockConfiguration) {
        self.configuration = configuration
    }
    
    var language: String {
        configuration.language ?? "code"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(language)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: {
                    Clipboard.set(configuration.content)
                    Toast.copy(title: "复制成功")
                }) {
                    Image(systemName: "doc.on.doc")
                        .padding(7)
                }
                .buttonStyle(GrowingButton())
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(MarkdownColors.secondaryBackground)
            
            Divider()
            
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.225))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(16)
            }
        }
        .background(MarkdownColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .markdownMargin(top: .zero, bottom: .em(0.8))
    }
}
