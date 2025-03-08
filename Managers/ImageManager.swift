//
//  ImageManager.swift
//  pushback
//
//  Created by uuneo 2024/10/14.
//

import SwiftUI
import CryptoKit
import Kingfisher

let lockQueue = DispatchQueue(label: "me.uuneo.Meoworld.lockQueue")

class ImageManager {


	class func storeImage(cache: ImageCache, data: Data, key: String, expiration: StorageExpiration) async {
		return await withCheckedContinuation { continuation in
			cache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
				continuation.resume()
			}
		}
	}


	class func storeImage(data: Data, key: String,localKey:String? = nil, expiration: StorageExpiration = .never,complete: ((Bool)->Void)? = nil){
		guard let cache = ImageManager.defaultCache(),
			  Defaults[.images].filter({$0.url == key}).count == 0 else {
			complete?(false)
			return
		}
		let sha256 = self.sha256(file: data)

		guard Defaults[.images].filter({$0.sha256 == sha256}).count == 0 else {
			complete?(false)
			return
		}

		cache.storeToDisk(data, forKey: key, expiration: expiration) { result in
			switch result.diskCacheResult{
				case .failure(_):
					complete?(false)
				default:
					Defaults[.images].insert(ImageModel(url: key,another: localKey,sha256: sha256), at: 0)
					complete?(true)
			}
		}
	}


	class func downloadImage(_ imageUrl: String, expiration: StorageExpiration = .never) async -> String? {

		var imageUrl = imageUrl

		///  先找本地url
		if let image = Defaults[.images].first(where: {$0.another == imageUrl}){ imageUrl = image.url }

		guard let cache = ImageManager.defaultCache() else { return nil }

		///  如果是本地文件直接返回
		guard let imageResource = URL(string: imageUrl), !imageResource.isFileURL else { return imageUrl }

		if cache.diskStorage.isCached(forKey: imageResource.cacheKey) { return cache.cachePath(forKey: imageResource.cacheKey) }

		///  下载图片
		guard let result = try? await downloadImage(url: imageResource).get() else { return nil }

		///  缓存图片
		await storeImage(cache: cache, data: result.originalData, key: imageResource.cacheKey, expiration: expiration)

		/// 本地记录方便本地化
		/// 检查是否已存在相同的 URL，防止重复写入
		lockQueue.sync {
			if !Defaults[.images].contains(where: { $0.url == imageUrl }) {
				Defaults[.images].insert(ImageModel(url: imageUrl,sha256: sha256(file: result.originalData)),at: 0)
			}
		}


		return  cache.cachePath(forKey: imageResource.cacheKey)


	}


	class func downloadImage(url: URL) async -> Result<ImageLoadingResult, KingfisherError> {
		return await withCheckedContinuation { continuation in
			Kingfisher.ImageDownloader.default.downloadImage(with: url, options: nil) { result in
				continuation.resume(returning: result)
			}
		}
	}


	class func defaultCache() -> ImageCache?{
		guard let groupUrl = BaseConfig.getImagesDirectory(),
			  let cache = try? ImageCache(name: "shared", cacheDirectoryURL: groupUrl) else {
			return nil
		}

		cache.diskStorage.config.sizeLimit = UInt(Defaults[.cacheSize].size)
		return cache
	}

	class func deleteImage(_ url:String, completion: ((Bool)-> Void)? = nil){
		guard let cache  = ImageManager.defaultCache() else {
			completion?( false)
			return
		}

		do{
			try cache.diskStorage.remove(forKey: url)
			Defaults[.images].removeAll(where: {$0.url ==  url})
			completion?(true)
		}catch{
			completion?(false)
		}


		completion?(false)
	}


	class func changeLocalKey(_ url:String, key:String)-> Bool{
		guard Defaults[.images].filter({$0.another == key}).count == 0 else { return false}
		guard  let index = Defaults[.images].firstIndex(where: {$0.url == url}) else { return false}
		Defaults[.images][index].another = key
		return true
	}

	class func sha256(file: Data) -> String {
		// 计算 SHA-256 哈希值
		let hash = SHA256.hash(data: file)
		// 将哈希值转换为十六进制字符串
		let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

		return hashString
	}


}

