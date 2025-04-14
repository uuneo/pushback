//
//  PushIntent.swift
//  pushback
//
//  Created by lynn on 2025/4/13.
//

import AppIntents

struct EasyPushIntent: AppIntent {
    
    static var title: LocalizedStringResource = "快速通知"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "*服务器")
    var address: String

    
    @Parameter(title: "标题")
    var title: String?
    
    @Parameter(title: "*内容")
    var body: String?
    
    @Parameter(title: "群组", default: "默认")
    var group: String?


    
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        
        guard let address = URL(string: address) else {
            throw "Invalid URL"
        }
        
        var params: [String: Any] = [:]
        
        
        if let group, !group.isEmpty{
            params["group"] = group
        }
        
        if let title, !title.isEmpty{
            params["title"] = title
        }
        
   
        if let body, !body.isEmpty{
            params["body"] = body
        }
 
        
        let http = NetworkManager()
        
        
        let res:APIPushToDeviceResponse? = try await http.fetch(url: address.absoluteString, method: .post, params: params)
        
        
        return .result(value: res?.code == 200)
    }
    
    
}

