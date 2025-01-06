//
//  File name:     ShareViewController.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2025/1/9.

import UIKit
import Social


class ShareViewController: SLComposeServiceViewController {


	override func isContentValid() -> Bool {
		// Do validation of contentText and/or NSExtensionContext attachments here
		if let localText = self.contentText {
			self.charactersRemaining = max(10 - self.contentText.count, 0) as NSNumber
			return (3...10).contains(localText.count) && Defaults[.images].filter({$0.another == self.contentText}).count == 0
		}

		return false
	}

	private func saveImage() {

		if let item = extensionContext?.inputItems.first as? NSExtensionItem,
		   let attachment =  (item.attachments?.first as? NSItemProvider),
		   attachment.hasItemConformingToTypeIdentifier("public.image"){

			attachment.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
				if let err = error{
					Log.debug(err.localizedDescription)
					return
				}
				if let data = data, let _ = UIImage(data: data), let text = self.contentText{
					ImageManager.storeImage(data: data, key:  URL(string: "mw://\(text).image")!.cacheKey,localKey: self.contentText, expiration: .never){success in
						self.openHostApp(localKey: self.contentText)
						Log.debug("图片保存状态\(success)")
						return
					}
				}
				Log.debug("图片保存失败")

			}
		}else{
			Log.debug("没有数据")
		}

	}


	override func didSelectPost() {
		// This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
		self.saveImage()
		// Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
		}
	}


	override func configurationItems() -> [Any]! {
		// To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
		return []
	}


	func openHostApp(localKey:String) {
		var responder: UIResponder? = self // 从当前对象开始

		while let currentResponder = responder {
			// 检查是否是 UIApplication 类型
			if let app = currentResponder as? UIApplication{
				app.open(URL(string: "mw://fromLocalImage?key=\(localKey)")!, options: [:]) { success in
					Log.debug("打开app状态：\(success)")
				}
				return
			}

			// 遍历下一个响应者
			responder = currentResponder.next
		}

		Log.debug("没有找到响应链")
	}

}
