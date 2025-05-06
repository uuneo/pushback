//
//  ChatMessageModel.swift
//  pushback
//
//  Created by uuneo on 2025/2/25.
//


import Foundation
import RealmSwift

final class ChatGroup: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var timestamp: Date
    @Persisted var name: String = String(localized: "新对话")
    @Persisted var host: String
    @Persisted var current:Bool = false
}

extension ChatGroup{
    func rename(_ name:String, complete:((Error?)->Void)? = nil){
        
        do{
            let realm = try Realm()
            guard let item = realm.objects(ChatGroup.self).filter({$0.id == self.id}).first else {
                complete?(nil)
                return
            }
            try realm.write{
                item.name = name
                complete?(nil)
            }
        }catch{
            Log.error(error.localizedDescription)
            complete?(error)
        }
    }
}



final class ChatMessage: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted(indexed: true) var chat:String
    @Persisted var request:String
    @Persisted var content: String
    @Persisted var timestamp: Date
    @Persisted var messageId:String?
    
}


extension ChatMessage{
    static func getAssistant(chat:ChatMessage?)-> Message{
        let message = Message()
        
        message.group = String(localized: "智能助手")
        message.body =  String(localized:"嗨! 我是智能助手,我可以帮你搜索，答疑，写作，请把你的任务交给我吧！")

        if let chat = chat{
            message.createDate = chat.timestamp
        }
        return message
    }
}


final class ChatPrompt: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    /// 提示词标题
    @Persisted var title: String
    /// 提示词内容
    @Persisted var content: String
    /// 远程更新
    @Persisted var address: String
    /// 是否为内置提示词
    @Persisted var isBuiltIn: Bool
    /// 创建时间
    @Persisted var timestamp: Date
    /// 是否被选中
    @Persisted var isSelected: Bool
    
    
    
    static let prompts = [
        
        ChatPrompt(value: ["title":String(localized: "代码助手"),"content":String(localized: """
             作为一名经验丰富的程序员，你擅长编写清晰、简洁且易于维护的代码。在回答问题时：
             1. 提供详细的代码示例。
             2. 解释代码的关键部分。
             3. 指出潜在的优化空间。
             4. 考虑代码的性能和安全性。
             """),"isBuiltIn":true]),
        ChatPrompt(value: ["title":String(localized: "翻译助手"),"content":String(localized: """
             作为一名专业翻译，你精通多国语言，擅长准确传达原文的含义和风格。你的职责包括：
             1. 保持原文的语气和风格。
             2. 考虑文化差异和语言习惯。
             3. 在必要时提供注释或说明。
             4. 对专业术语进行解释和澄清。
             """),"isBuiltIn":true]),
        ChatPrompt(value: ["title":String(localized: "写作助手"),"content":String(localized: """
             作为一名专业写作助手，你擅长各类文体的写作和润色。你的任务包括：
             1. 改进文章结构和逻辑。
             2. 优化用词和表达方式。
             3. 确保文章连贯性和流畅性。
             4. 突出重点内容和核心信息。
             5. 使文章符合目标读者的阅读习惯。
             """),"isBuiltIn":true]),
    ]
}
