//
//  DeleteMessages.swift
//  pushback
//
//  Created by lynn on 2025/4/14.
//

import AppIntents
import SwiftUI
import RealmSwift

struct DeleteMessageIntent: AppIntent {
    
    static var title: LocalizedStringResource = "删除消息"
    static var openAppWhenRun: Bool = false
    
    
    @Parameter(title: "日期")
    var date: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("删除 \(\.$date) 之前的消息")
    }
    
    @MainActor
    func perform()  async throws -> some IntentResult {
        let realm = try await Realm()
        
        let datas = realm.objects(Message.self).where({$0.createDate < date})
        try? realm.write {
            realm.delete(datas)
        }
        return .result()
    }
}
