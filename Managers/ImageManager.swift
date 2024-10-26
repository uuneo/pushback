//
//  ImageManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
//

import SwiftUI
import CryptoKit
import Defaults


extension Defaults.Keys{
	static let images = Key<[String]>("imagesCache", default: [], suite: DEFAULTSTORE )
}


class ImageManager {
	
	// Public method to retrieve or download an image
	class func fetchImage(from url: String) async -> String? {
		// First, check if the image already exists in the local cache
		if let cachedImage = await loadImageFromCache(for: url) {
			print("Image loaded from cache for URL: \(url)")
			return cachedImage
		}
		
		// If the image doesn't exist locally, download it from the URL
		guard let image = await downloadImage(url),
			  let fileUrl = await storeImage(from: url, at: image)
		else {
			print("Failed to download image from URL: \(url)")
			return nil
		}
		
		return fileUrl
	}
	
	// New method to rename an image file
	class func renameImage(oldName: String, newName: String) -> Bool {
		guard let imagesDirectory = getImagesDirectory(),
			  let oldName1 = sha256(from: oldName),
			  let newName1 = sha256(from: newName)
		else {
			print("Images directory not found")
			return false
		}
		
		let oldPath = imagesDirectory.appendingPathComponent(oldName1).appendingPathExtension("png")
		let newPath = imagesDirectory.appendingPathComponent(newName1).appendingPathExtension("png")
		
		if !FileManager.default.fileExists(atPath: oldPath.path) {
			print("File not found at path: \(oldPath.absoluteString)")
			return false
		}
		
		do {
			try FileManager.default.moveItem(at: oldPath, to: newPath)
			
			if let index = Defaults[.images].firstIndex(of: oldName){
				Defaults[.images][index] = newName
			}
			
			print("File renamed from \(oldName) to \(newName)")
			
			return true
		} catch {
			print("Failed to rename file: \(error.localizedDescription)")
			return false
		}
	}
	
	// Method to store the image in the local cache
	class func storeImage(from url: String, at image: UIImage) async -> String? {
		guard let imagesDirectory = getImagesDirectory(),
			  let imageData = image.pngData(),
			  let name = sha256(from: url) else {
			print("Failed to convert image to PNG data")
			return nil
		}
		
		// Construct the full image path
		let imagePath = imagesDirectory.appendingPathComponent(name).appendingPathExtension("png")
		
		// Save the image data to the file system
		do {
			try imageData.write(to: imagePath)
			await MainActor.run {
				Defaults[.images].insert(url, at: 0)
			}
			print("Image successfully saved at: \(imagePath)")
			return imagePath.path
		} catch {
			print("Failed to save image: \(error.localizedDescription)")
		}
		
		return nil
	}
	
	
	// Method to delete an image file
	class func deleteImage(for url: String) async -> Bool {
		guard let imagesDirectory = getImagesDirectory(),
			  let name = sha256(from: url) else {
			print("Failed to generate path for cached image")
			return false
		}
		
		// Construct the full image path
		let imagePath = imagesDirectory.appendingPathComponent(name).appendingPathExtension("png")
		
		// Check if the file exists and delete it
		if FileManager.default.fileExists(atPath: imagePath.path) {
			do {
				try FileManager.default.removeItem(at: imagePath)
				await MainActor.run {
					Defaults[.images].removeAll(where: {$0 == url})
				}
				print("Image successfully deleted at: \(imagePath)")
				return true
			} catch {
				print("Failed to delete image: \(error.localizedDescription)")
				return false
			}
		} else {
			print("Image not found at path: \(imagePath.absoluteString)")
			return false
		}
	}
	
	// Method to load image from local cache if it exists
	fileprivate static func loadImageFromCache(for url: String) async -> String? {
		guard let imagesDirectory = getImagesDirectory(),
			  let name = sha256(from: url) else {
			print("Failed to generate path for cached image")
			return nil
		}
		
		// Construct the full image path
		let imagePath = imagesDirectory.appendingPathComponent(name).appendingPathExtension("png")
		
		// Check if the file exists at the path
		if FileManager.default.fileExists(atPath: imagePath.path) {
			return imagePath.path
		} else {
			print("Image not found in cache")
		}
		
		return nil
	}
	
	// Download the image from a URL
	fileprivate static func downloadImage(_ url: String) async -> UIImage? {
		guard let url = URL(string: url) else {
			print("Invalid URL: \(url)")
			return nil
		}
		
		let urlRequest = URLRequest(url: url)
		
		do {
			let (data, response) = try await URLSession.shared.data(for: urlRequest)
			
			// Check HTTP response status
			guard let response = response as? HTTPURLResponse else {
				print("Invalid HTTP response")
				return nil
			}
			
			guard 200...299 ~= response.statusCode else {
				print("Failed with status code: \(response.statusCode)")
				return nil
			}
			
			// Convert data to UIImage
			guard let image = UIImage(data: data) else {
				print("Failed to decode image from data")
				return nil
			}
			
			return image
		} catch URLError.notConnectedToInternet {
			print("No internet connection")
			return nil
		} catch URLError.timedOut {
			print("Request timed out")
			return nil
		} catch {
			print("Failed to download image: \(error.localizedDescription)")
			return nil
		}
	}
	
	// Get the directory to store images in the App Group
	fileprivate static func getImagesDirectory() -> URL? {
		guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.pushback") else {
			return nil
		}
		let imagesDirectory = containerURL.appendingPathComponent("Images")
		
		// If the directory doesn't exist, create it
		if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
			do {
				try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print("Failed to create images directory: \(error.localizedDescription)")
				return nil
			}
		}
		return imagesDirectory
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
		
		guard let imagesDirectory = getImagesDirectory() else {
			return
		}

		do {
			// 获取文件夹中所有文件的路径
			let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: imagesDirectory.path), includingPropertiesForKeys: nil)
			
			for fileURL in fileURLs {
				
				let fileName = fileURL.lastPathComponent
				// 检查文件是否在列表中
				let validFileNames = allData ?  [] : Defaults[.images].compactMap({ sha256(from: $0) })
				
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
	
	
	
	
}
