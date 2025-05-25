//
//  NotificationViewController.swift
//  NotificationContentExtension
//
//  Created by lynn on 2025/4/3.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import Defaults
import AVFoundation


class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var musicView: UIView!
    
    var memorySize:CGSize = .zero
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        // 添加长按手势到图片视图
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnImage(_:)))
        self.imageView.isUserInteractionEnabled = true // 确保图片视图可以交互
        self.imageView.addGestureRecognizer(longPressGesture)
    }
    
    


    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        // 兼容bark
        if userInfo[Params.autocopy.name] as? String == "1" {
            if let copy = userInfo[Params.copy.name] as? String {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = notification.request.content.body
            }
        }
        
        let imageList = mediaHandler(userInfo: userInfo, name: Params.image.name)
        
       
        
        self.musicView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 50)
        
        var music: MusicInfoView{
            let music = MusicInfoView()
            music.text = userInfo.voiceText()
            music.frame = musicView.frame
            return music
        }
       
       
        self.musicView.addSubview(music)
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: 50)
        if let imageUrl = imageList.first {   ImageHandler(imageUrl: imageUrl) }
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case Identifiers.muteAction:
            let group = response.notification.request.content.threadIdentifier
            Defaults[.muteSetting][group] = Date().addingTimeInterval(60 * 60)
            showTips(text:  String(localized: "[\(group)]分组静音成功"))
            completion(.doNotDismiss)
        case Identifiers.copyAction:
            if let copy = userInfo[Params.copy.name] as? String {
                UIPasteboard.general.string = copy
            } else {
                UIPasteboard.general.string = response.notification.request.content.body
            }
            showTips(text:String(localized: "复制成功"))
            completion(.doNotDismiss)
        default:
            completion(.doNotDismiss)
        }
        
    }



    func ImageHandler(imageUrl: String) {
        Task.detached(priority: .high) {

            if let localPath = await ImageManager.downloadImage(imageUrl, expiration: .days(Defaults[.imageSaveDays].rawValue)),
               let image = UIImage(contentsOfFile: localPath) {

                let size = await self.sizecalculation(size: image.size)

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.imageView.image = image
                   
                    self.imageView.frame = CGRect(x: 0, y: 50, width: size.width, height: size.height)
                    self.preferredContentSize = .init(width: size.width, height: size.height + 50)
                }
            } else {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.preferredContentSize = CGSize(width: self.view.bounds.width, height: 50)
                }
            }
        }
    }

    func sizecalculation(size: CGSize) -> CGSize {
        let viewWidth = view.bounds.size.width
        let aspectRatio = size.width / size.height
        let viewHeight = viewWidth / aspectRatio
        self.preferredContentSize = CGSize(width: viewWidth, height: viewHeight)
        return self.preferredContentSize
    }
    
  
    func showTips(text: String) {
        self.memorySize = self.preferredContentSize
        
        if self.preferredContentSize.height < 200{
            self.preferredContentSize = CGSize(width: self.view.bounds.width, height: 200)
        }
        
        let alert = UIAlertController(title: String(localized: "提示") + ":", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "确定"), style: .default, handler: { _ in
            self.preferredContentSize = self.memorySize
            self.memorySize = .zero
        }))

        // 在 UIViewController 里弹出
        present(alert, animated: true, completion: nil)
    }
    

}

extension NotificationViewController{
    

    func mediaHandler(userInfo:[AnyHashable:Any], name:String) -> [String]{

        if let media = userInfo[name] as? String{
            return [media]
        }else if let medias = userInfo[name] as? [String]{
            return medias
        }
        return []
    }


    // 长按手势回调方法
    @objc func handleLongPressOnImage(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        guard let image = imageView.image else { return }

        // 弹出保存选项
        let alertController = UIAlertController(title: String(localized:"保存图片"), message:  String(localized:"是否将图片保存到相册？"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title:  String(localized:"保存"), style: .default, handler: { _ in
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        alertController.addAction(UIAlertAction(title:  String(localized:"取消"), style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    // 保存完成后的回调方法
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alertController: UIAlertController

        if let error = error {
            // 保存失败提示
            alertController = UIAlertController(
                title:  String(localized:"保存失败"),
                message:  String(localized:"保存图片时出现错误：\(error.localizedDescription)"),
                preferredStyle: .alert
            )
        } else {
            // 保存成功提示
            alertController = UIAlertController(
                title:  String(localized:"保存成功"),
                message:  String(localized:"图片已成功保存到相册！"),
                preferredStyle: .alert
            )
        }

        // 添加确定按钮
        alertController.addAction(UIAlertAction(title:  String(localized:"确定"), style: .default, handler: nil))

        // 显示弹窗
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }


}
