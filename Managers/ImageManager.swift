//
//  ImageManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
//

import SwiftUI
import CryptoKit
import Defaults


extension Defaults.Keys {
	static let images = Key<[ImageCacheModal]>("imagesCache", default: [], suite: DEFAULTSTORE )
	static let imageSaveDays = Key<ExpirationTime>(BaseConfig.imageSaveDays,default: .forever, suite: DEFAULTSTORE)
}



class ImageManager {
	
	// Public method to retrieve or download an image
	class func fetchImage(from url: String) async -> ImageCacheModal? {
		// First, check if the image already exists in the local cache
		if let cachedImage = await loadImageFromCache(for: url) {
			return cachedImage
		}
		
		// If the image doesn't exist locally, download it from the URL
		guard let image = await downloadImage(url),
			  let fileUrl = await storeImage(from: url, at: image)
		else {
			return nil
		}
		
		return fileUrl
	}
	
	// New method to rename an image file
	class func renameImage(item: ImageCacheModal, newName: String) -> Bool {
		
		var newImage = item

		guard let imagesDirectory = BaseConfig.getImagesDirectory(),
			  let oldPath = item.localPath,
			  let newkey = sha256(from: newName)
		else {
			print("Images directory not found")
			return false
		}
		
		let newPath = imagesDirectory.appendingPathComponent(newkey)
		
		if !FileManager.default.fileExists(atPath: oldPath.path) {
			print("File not found at path: \(oldPath.path)")
			return false
		}
		
		do {
			try FileManager.default.moveItem(at: oldPath, to: newPath)
			
			if let index = Defaults[.images].firstIndex(where: {$0.key == item.key }){
				newImage.key = newkey
				newImage.local = newName
				Defaults[.images][index] = newImage
			}
			
			print("File renamed from \(item.key) to \(newName)")
			
			return true
		} catch {
			print("Failed to rename file: \(error.localizedDescription)")
			return false
		}
	}
	
	// Method to store the image in the local cache
	class func storeImage(from url: String, at image: UIImage, local:Bool = false) async -> ImageCacheModal? {
		
		guard let imagesDirectory = BaseConfig.getImagesDirectory(),
			  let imageData = image.pngData(),
			  let name = sha256(from: url) else {
			print("Failed to convert image to PNG data")
			return nil
		}
		
		
		
		let imageCache = ImageCacheModal(url: url, local: (local ? url : nil), key: name)
		
		// Construct the full image path
		let imagePath = imagesDirectory.appendingPathComponent(name)
		
		// Save the image data to the file system
		do {
			try imageData.write(to: imagePath)
			await MainActor.run {
				Defaults[.images].insert(imageCache, at: 0)
			}
			print("Image successfully saved at: \(imagePath)")
			return imageCache
		} catch {
			print("Failed to save image: \(error.localizedDescription)")
		}
		
		return nil
	}
	
	
	// Method to delete an image file
	class func deleteImage(for item: ImageCacheModal) async -> Bool {
		
		// Construct the full image path
		guard let imagePath = item.localPath  else {
			return false
		}
		
		// Check if the file exists and delete it
		if FileManager.default.fileExists(atPath: imagePath.path) {
			do {
				try FileManager.default.removeItem(at: imagePath)
				await MainActor.run {
					Defaults[.images].removeAll(where: {$0.name == item.name})
				}
				print("Image successfully deleted at: \(imagePath)")
				return true
			} catch {
				print("Failed to delete image: \(error.localizedDescription)")
				return false
			}
		} else {
			
			Defaults[.images].removeAll(where: {$0.name == item.name})
			
			print("Image not found at path: \(imagePath.path)")
			return false
		}
	}
	
	// Method to load image from local cache if it exists
	fileprivate static func loadImageFromCache(for url: String) async -> ImageCacheModal? {
		
		
		guard let imageCache = Defaults[.images].filter({$0.name == url}).first else {
			return nil
		}
		
		return imageCache

	}
	
	// Download the image from a URL
	fileprivate static func downloadImage(_ url: String) async -> UIImage? {

		guard url.isValidURL() == .remote, let url = URL(string: url)  else {
			print("Invalid URL: \(url)")
			return nil
		}
		
		let urlRequest = URLRequest(url: url)

		do {
			let data = try await URLSession(configuration: .default).data(for: urlRequest, timeout: 30)

			// Convert data to UIImage
			guard let image = UIImage(data: data) else {
				print("Failed to decode image from data")
				return nil
			}

			return image

		} catch {
			print("Failed to download image: \(error.localizedDescription)")
			return nil
		}
	}


	
	// Generate SHA-256 hash for a given URL
	fileprivate static func sha256(from url: String) -> String? {
		guard let urlData = url.data(using: .utf8) else { return nil }
		let hashed = SHA256.hash(data: urlData)
		return hashed.compactMap { String(format: "%02x", $0) }.joined()
	}
	

	
	class func deleteFilesNotInList(all allData:Bool = false) async {
		
		if allData{
			await MainActor.run {
				Defaults[.images] = []
			}
		}
		
		let fileManager = FileManager.default
		
		guard let imagesDirectory = BaseConfig.getImagesDirectory() else {
			return
		}

		do {
			// 获取文件夹中所有文件的路径
			let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: imagesDirectory.path), includingPropertiesForKeys: nil)
			
			for fileURL in fileURLs {
				
				let fileName = fileURL.lastPathComponent
				// 检查文件是否在列表中
				let validFileNames = allData ?  [] : Defaults[.images].compactMap({ $0.key})
				
				if !validFileNames.contains(fileName) {
					// 如果文件不在列表中，删除该文件
					do {
						try fileManager.removeItem(at: fileURL)
					
						print("Deleted: \(fileName)")
					} catch {
						print("Failed to delete: \(fileName), error: \(error)")
					}
				}
			}
			
		} catch {
			print("Error reading contents of folder: \(error)")
		}
	}
	
	class func deleExpired() async {
		let days = Defaults[.imageSaveDays]
		let images = Defaults[.images].filter({$0.local == nil && $0.createDate.isExpired(days: days.days)})
		for image in images{
			_ = await self.deleteImage(for: image)
		}
	}
	
	
	
}
