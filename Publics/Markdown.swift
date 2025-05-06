//
//  Markdown.swift
//  pushback
//
//  Created by lynn on 2025/5/15.
//

import Foundation
import cmark_gfm
import cmark_gfm_extensions


class PBMarkdown{
    class func plain(_ markdown: String) -> String {
        // 注册 GFM 扩展
        cmark_gfm_core_extensions_ensure_registered()
        
        // 创建解析器
        guard let parser = cmark_parser_new(CMARK_OPT_DEFAULT) else { return "" }
        let extensionNames: Set<String> =  ["autolink", "strikethrough", "tagfilter", "tasklist", "table"]
        
        for extensionName in extensionNames {
            guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
                continue
            }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }
        // 解析 Markdown
        cmark_parser_feed(parser, markdown, markdown.utf8.count)
        
        guard let doc = cmark_parser_finish(parser) else { return "" }
        
        // 渲染为 HTML
        
        if let text = cmark_render_plaintext(doc, 0, 0) {
            return String(cString: text)
        }
        
        
        
        defer {
            // 释放资源
            cmark_node_free(doc)
            cmark_parser_free(parser)
        }
        
        return ""
    }
    
    class func markdownToHTML(_ markdown: String) -> String? {
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
