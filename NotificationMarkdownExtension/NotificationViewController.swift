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
    @IBOutlet weak var musicView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.frame = view.bounds
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.preferredContentSize = CGSize(width: view.bounds.width, height: 10) // 初始高度
        
        // 监听 WKWebView 高度变化
        web.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        

    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let scrollView = object as? UIScrollView {
            
            if scrollView.contentSize.height > self.preferredContentSize.height{
                self.preferredContentSize = CGSize(width: self.view.bounds.width, height: max(10, scrollView.contentSize.height + 50))
            }
            
        }
    }

    deinit {
        web.scrollView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    
    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        self.musicView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50)
        
        
        var music: MusicInfoView{
            let music = MusicInfoView()
            music.text = userInfo.voiceText()
            music.frame = musicView.frame
            return music
        }
       
        self.musicView.addSubview(music)
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: 50)
        
        if let body:String = userInfo.raw(Params.body),
           let htmlContent = convertMarkdownToHTML(body),
           let cssPath = Bundle.main.path(forResource: "markdown", ofType: "css") {
            let baseURL = URL(fileURLWithPath: cssPath).deletingLastPathComponent()
            web.loadHTMLString(htmlContent, baseURL:baseURL)
            
        } else {
            web.loadHTMLString("<h1>Error loading content</h1>", baseURL: nil)
        }
        web.frame = .init(x: 0, y: 50, width: self.view.bounds.width, height: web.frame.height)
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String? {
       
        guard let htmlBody =  PBMarkdown.markdownToHTML(markdown) else { return nil }
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
    
}
