//
//  test.swift
//  pushback
//
//  Created by lynn on 2025/3/13.
//

import SwiftUI
import Down
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdownText: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let html = try? Down(markdownString: markdownText).toHTML() {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
}


struct ContentView: View {
    let markdown = """
    # 你好, SwiftUI!
    这是 **Markdown** 渲染示例。
    - 列表项 1
    - 列表项 2
    """

    var body: some View {
        MarkdownWebView(markdownText: markdown)
            .frame(height: 300)
    }
}
