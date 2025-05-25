//
//  TextFileMessage.swift
//  pushback
//
//  Created by lynn on 2025/5/25.
//
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import RealmSwift

struct TextFileMessage: FileDocument {

    static var readableContentTypes: [UTType] { [.trnExportType] } // 使用 JSON 文件类型

    var content: [MessageCopy]

    // 初始化器（设置默认内容）
    init(content: [MessageCopy]) {
        self.content = content
    }

    // 从文件中读取内容
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let content = try decoder.decode([MessageCopy].self, from: data)
        self.content = content
    }

    // 写入内容到文件
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // 格式化输出
        encoder.dateEncodingStrategy = .secondsSince1970

        let data = try encoder.encode(content)
        return FileWrapper(regularFileWithContents: data)
    }
    
    
   
}
