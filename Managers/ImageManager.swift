//
//  ImageManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
//

import SwiftUI
import CryptoKit
import Kingfisher


class ImageManager {
	

	class func storeImage(cache: ImageCache, data: Data, key: String, expiration: StorageExpiration) async {
		return await withCheckedContinuation { continuation in
			cache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
				continuation.resume()
			}
		}
	}


	class func storeImage(data: Data, key: String, expiration: StorageExpiration, completion: ((Bool)-> Void)? = nil)  async {
		guard let cache = ImageManager.defaultCache() else { return }
		cache.storeToDisk(data, forKey: key, expiration: expiration) { result in
			switch result.diskCacheResult{
				case .failure(_):
					completion?(false)
				default:
					if Defaults[.images].filter({$0.url == key}).count == 0{
						Defaults[.images].append(ImageModel(url: key))
					}
					completion?(true)
			}
		}
	}


	class func downloadImage(_ imageUrl: String, expiration: StorageExpiration = .never) async -> String? {

		guard let cache = ImageManager.defaultCache() else { return nil }

		// 先判断是否有本地字符串的图片
		if cache.diskStorage.isCached(forKey: imageUrl) {
			return  cache.cachePath(forKey: imageUrl)
		}


		guard let imageResource = URL(string: imageUrl), !imageResource.isFileURL else { return imageUrl }

		if cache.diskStorage.isCached(forKey: imageResource.cacheKey) {
			return  cache.cachePath(forKey: imageResource.cacheKey)
		}

		// 下载图片
		guard let result = try? await downloadImage(url: imageResource).get() else {
			return nil
		}


		// 缓存图片
		await storeImage(cache: cache, data: result.originalData, key: imageResource.cacheKey, expiration: expiration)

		/// 本地记录方便本地化
		if Defaults[.images].filter({$0.url == imageUrl}).count == 0{
			Defaults[.images].append(ImageModel(url: imageUrl))
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
			if let cacheUrl = URL(string: url){
				try cache.diskStorage.remove(forKey: cacheUrl.cacheKey)
				completion?(true)
			}else{
				try cache.diskStorage.remove(forKey: url)
			}

		}catch{
			completion?(false)
		}


		completion?(false)
	}

}
