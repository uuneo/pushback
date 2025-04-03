//
//  image+.swift
//  Meow
//
//  Created by uuneo 2024/8/29.
//

import UIKit
import Photos
import SwiftUI

//MARK: - 保存图片到相册
extension UIImage {
    /// 保存图片到相册
    /// 需要授权`Privacy - Photo Library Additions Usage Description`和`Privacy - Photo Library Usage Description`
    /// @param albumName 自定义相册的名字
    /// @param complete `success`代表图片保存是否成功,`authorizationStatus`代表授权状态
    func bat_save(intoAlbum albumName: String?, complete: @escaping (_ success: Bool, _ authorizationStatus: PHAuthorizationStatus) -> ()) {
        
        let oldStatus = PHPhotoLibrary.authorizationStatus()
        PHPhotoLibrary.requestAuthorization({ status in
			DispatchQueue.main.async{
				if status == .denied {
					// 用户拒绝当前App访问相册
					if oldStatus != .notDetermined {
						// 提醒用户打开开关
						complete(false, PHAuthorizationStatus.denied)
					}
				} else if status == .authorized {
					// 用户允许当前App访问相册
					self.p_excuteSaveImage(intoAlbum: albumName, complete: complete)
					complete(true, .authorized)
				} else if status == .restricted {
					// 无法访问相册
					complete(false, .restricted)
				}
			}
            
        })
    }
    
    /// 私有的，负责具体的保存图片的操作
    private func p_excuteSaveImage(intoAlbum albumName: String?, complete: @escaping (_ success: Bool, _ authorizationStatus: PHAuthorizationStatus) -> ()) {
        
        // 如果没有设置albumName或albumName为空,则直接保存到`相机胶卷`
        if albumName == nil || albumName!.count == 0 {
            // 保存图片到`相机胶卷`
            guard let _ = try? PHPhotoLibrary.shared().performChangesAndWait({
                PHAssetChangeRequest.creationRequestForAsset(from: self)
            }) else {
                complete(false, .authorized)
                return
            }
            complete(true, .authorized)
            return
        }
        
        // 获得相片
        guard let createdAssets = p_createdAssets() else {
            complete(false, .authorized)
            return
        }

        // 获得相册
        guard let createdCollection = p_createdCollection(albumName: albumName!) else {
            complete(false, .authorized)
            return
        }
        
        // 添加刚才保存的图片到`自定义相册`
        guard let _ = try? PHPhotoLibrary.shared().performChangesAndWait({
            let request = PHAssetCollectionChangeRequest(for: createdCollection)
            request?.insertAssets(createdAssets, at: NSIndexSet(index: 0) as IndexSet)
        }) else {
            complete(false, .authorized)
            return
        }
        // 最后的判断
        complete(true, .authorized)
    }
    
    /// 当前App对应的自定义相册
    private func p_createdCollection(albumName: String) -> PHAssetCollection? {
        
        // 抓取所有的自定义相册
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        
        // 查找当前App对应的自定义相册
        for index in 0..<collections.count {
            let collection = collections.object(at: index)
            if collection.localizedTitle == albumName {
                return collection
            }
        }
        
        // 当前App对应的自定义相册没有被创建过
        // 创建一个`自定义相册`
        var createdCollectionID: String = ""
        guard let _ = try? PHPhotoLibrary.shared().performChangesAndWait({
            createdCollectionID = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName).placeholderForCreatedAssetCollection.localIdentifier
        }) else {
            return nil
        }
        
        // 根据唯一标识获得刚才创建的相册
        return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [createdCollectionID], options: nil).firstObject
    }
    
    /// 返回刚才保存到`相机胶卷`的图片
    private func p_createdAssets() -> PHFetchResult<PHAsset>? {
        
        var assetID: String = ""
        guard let _ = try? PHPhotoLibrary.shared().performChangesAndWait({
            assetID = PHAssetChangeRequest.creationRequestForAsset(from: self).placeholderForCreatedAsset?.localIdentifier ?? ""
        }) else {
            return nil
        }
        return PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
    }
}



extension Image {
	func customDraggable(_ width:CGFloat = .zero, appear:((Image)-> Void)? = nil, disappear:((Image)-> Void)? = nil) -> some View{
		self
			.draggable(self){
				self
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: width == .zero ? 300 : width)
					.onAppear{
						appear?(self)
					}
					.onDisappear{
						disappear?(self)
					}
			}
	}
}
