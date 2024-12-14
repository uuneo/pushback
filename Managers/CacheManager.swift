//
//  File name:     CacheManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/14.
	
import Foundation

class CacheManager {

	private let groupFolder: URL
	private let maxSize: Int64


	init(groupFolder: URL, maxSize: Int64) {
		self.groupFolder = groupFolder
		self.maxSize = maxSize
	}

	func calculateCacheSize() -> Int64 {
		let fileManager = FileManager.default
		var totalSize: Int64 = 0

		if let files = try? fileManager.contentsOfDirectory(at: groupFolder, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles) {
			for file in files {
				if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
					totalSize += Int64(fileSize)
				}
			}
		}
		return totalSize
	}

	func manageCache() {
		let fileManager = FileManager.default

		var files = (try? fileManager.contentsOfDirectory(at: groupFolder, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles)) ?? []

		files.sort { (file1, file2) -> Bool in
			let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
			let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
			return date1 < date2
		}

		var currentSize = calculateCacheSize()

		for file in files {
			if currentSize <= maxSize { break }

			if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize  {
				try? fileManager.removeItem(at: file)
				currentSize -= Int64(fileSize)
			}
		}
	}

	// 清空指定文件夹中的所有文件
	class func clearFolder(at folderURL: URL) -> Bool {
		let fileManager = FileManager.default

		do {
			// 获取文件夹中的所有文件的路径
			let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)

			// 遍历文件夹中的文件并删除
			for fileURL in fileURLs {
				do {
					try fileManager.removeItem(at: fileURL)
					print("Deleted file: \(fileURL.lastPathComponent)")
				} catch {
					print("Failed to delete file \(fileURL.lastPathComponent), error: \(error)")
				}
			}
			return true
		} catch {
			print("Error reading contents of folder: \(error)")
			return false
		}
	}
}
