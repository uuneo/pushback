//
//  NotificationViewController.swift
//  NotificationMarkdownExtension
//
//  Created by lynn on 2025/4/3.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import cmark_gfm
import cmark_gfm_extensions
import WebKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var web: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.frame = view.bounds
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.preferredContentSize = CGSize(width: view.bounds.width, height: 100) // 初始高度
        
        // 监听 WKWebView 高度变化
        web.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        

    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let scrollView = object as? UIScrollView {
            
            if scrollView.contentSize.height > self.preferredContentSize.height{
                self.preferredContentSize = CGSize(width: self.view.bounds.width, height: max(100, scrollView.contentSize.height))
            }
            
        }
    }

    deinit {
        web.scrollView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        if let alert = (userInfo[Params.aps.name] as? [String: Any])?[Params.alert.name] as? [String: Any],
            let body = alert[Params.body.name] as? String,
           let htmlContent = convertMarkdownToHTML(body),
           let cssPath = Bundle.main.path(forResource: "markdown", ofType: "css") {
            let baseURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
            web.loadHTMLString(htmlContent, baseURL:baseURL)
        } else {
            web.loadHTMLString("<h1>Error loading content</h1>", baseURL: nil)
        }
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String? {
        guard let htmlBody = markdownToHTML(markdown) else { return nil }
        return """
        <html>
        <head>
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
            <link rel="stylesheet" type="text/css" href="markdown.css">
             <style>
                  body { font-family: -apple-system; padding: 10px; color: #333; background: #fff; }
                  img { max-width: 100%; height: auto; background: #ff0000;border-radius: 10px;}
                  pre { background: #f4f4f4; padding: 10px; overflow-x: auto; border-radius: 5px; }
                  code { font-family: monospace; color: #d63384; }
                  blockquote { color: #6a737d; padding-left: 10px; border-left: 4px solid #dfe2e5; }
                  h1, h2, h3 { color: #0056b3; }
                  @media (prefers-color-scheme: dark) {
                      body { background: #121212; color: #ffffff}
                      pre { background: #1e1e1e; }
                      blockquote { color: #bbb; border-left-color: #444; }
                      h1, h2, h3 { color: #4da3ff; }
                  }
             </style>
        </head>
        <body>
        <article class="markdown-body">
            \(htmlBody)
        </article>
        </body>
        </html>
        """
    }
    
    private func markdownToHTML(_ markdown: String) -> String? {
        // 注册 GFM 扩展
        cmark_gfm_core_extensions_ensure_registered()

        // 创建解析器
        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else {
            
            return nil
        }
        let extensionNames: Set<String> =  ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        
        for extensionName in extensionNames {
          guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
            continue
          }
          cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
        // 解析 Markdown
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        
        guard let doc = cmark_parser_finish(parser) else { return nil }

        // 渲染为 HTML
       
        if let html = cmark_render_html(doc, 0, nil) {
           return String(cString: html)
        }

        defer {
            // 释放资源
            cmark_node_free(doc)
            cmark_parser_free(parser)
        }
       
        return nil
    }
    
}
