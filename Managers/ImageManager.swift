//
//  ImageManager.swift
//  pushback
//
//  Created by uuneo 2024/10/14.
//

import SwiftUI
import Kingfisher


class ImageManager {


    class func storeImage(cache: ImageCache, data: Data, key: String, expiration: StorageExpiration = .never) async {
        return await withCheckedContinuation { continuation in
            cache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }
    
    
    class func storeImage(mode: BaseConfig.ImageMode = .icon,data: Data, key: String, expiration: StorageExpiration = .never) async {
        guard let cache = ImageManager.defaultCache(mode: mode) else { return}
        return await withCheckedContinuation { continuation in
            cache.storeToDisk(data, forKey: key, expiration: expiration) { _ in
                continuation.resume()
            }
        }
    }
    
    
    

    class func downloadImage(_ imageUrl: String, mode: BaseConfig.ImageMode = .icon, expiration: StorageExpiration = .never) async -> String? {

        guard let cache = ImageManager.defaultCache(mode: mode) else { return nil }
        
        
        // 如果是云图标直接判断返回
        if cache.diskStorage.isCached(forKey: imageUrl) {  return cache.cachePath(forKey: imageUrl) }

		guard let imageResource = URL(string: imageUrl) else { return nil }
        
        let cacheKey = imageResource.cacheKey

		if cache.diskStorage.isCached(forKey: cacheKey) { return cache.cachePath(forKey: cacheKey) }

		///  下载图片
		guard let result = try? await downloadImage(url: imageResource).get() else { return nil }

		///  缓存图片
		await storeImage(cache: cache, data: result.originalData, key: cacheKey, expiration: expiration)

		return  cache.cachePath(forKey: cacheKey)


	}


	class func downloadImage(url: URL) async -> Result<ImageLoadingResult, KingfisherError> {
		return await withCheckedContinuation { continuation in
			Kingfisher.ImageDownloader.default.downloadImage(with: url, options: nil) { result in
				continuation.resume(returning: result)
			}
		}
	}


    class func defaultCache(mode: BaseConfig.ImageMode = .icon) -> ImageCache?{
        guard let containerURL = BaseConfig.getImagesDirectory(mode: mode),
			  let cache = try? ImageCache(name: "shared", cacheDirectoryURL: containerURL) else { return nil }

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
			completion?(true)
		}catch{
			completion?(false)
		}


		completion?(false)
	}

}


