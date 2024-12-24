//
//  ImageManager.swift
//  pushback
//
//  Created by He Cho on 2024/10/14.
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


	class func storeImage(data: Data, key: String, expiration: StorageExpiration)  async -> Bool {
		guard let cache = ImageManager.defaultCache(),
			  Defaults[.images].filter({$0.url == key}).count == 0 else {
			return false
		}

		return await withCheckedContinuation { continuation in
			cache.storeToDisk(data, forKey: key, expiration: expiration) { result in
				switch result.diskCacheResult{
					case .failure(_):
						continuation.resume(returning: false)
					default:
						Defaults[.images].append(ImageModel(url: key))
						continuation.resume(returning: true)
				}
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
				Defaults[.images].append(ImageModel(url: imageUrl))
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

}

