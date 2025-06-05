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

    
    @IBOutlet weak var musicView: UIView!
    @IBOutlet weak var tipsView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var voiceHeight: CGFloat{
        Defaults[.showVoiceView] ? 35 : 0
    }
    
    var contentSize: CGSize{
        let height = imageView.bounds.height + musicView.bounds.height + tipsView.bounds.height
        return  CGSize(width: view.bounds.width, height: height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        self.musicView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: voiceHeight)
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0)
        self.tipsView.text = ""
        self.tipsView.adjustsFontForContentSizeCategory = true
        self.tipsView.textAlignment = .center
        self.tipsView.font = UIFont.preferredFont(ofSize: 16)
        self.tipsView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0)
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
        
        var music: MusicInfoView{
            let music = MusicInfoView()
            music.text = userInfo.voiceText()
            music.frame = musicView.frame
            return music
        }
        self.musicView.addSubview(music)
        self.preferredContentSize = CGSize(width: self.view.bounds.width, height: voiceHeight)
        
        let imageList = mediaHandler(userInfo: userInfo, name: Params.image.name)
        if let imageUrl = imageList.first { ImageHandler(imageUrl: imageUrl) }
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
        completion(.doNotDismiss)
    }



    func ImageHandler(imageUrl: String) {
        Task.detached(priority: .high) {
            if let localPath = await ImageManager.downloadImage(imageUrl, expiration: .days(Defaults[.imageSaveDays].rawValue)),
               let image = UIImage(contentsOfFile: localPath) {

                let size = await self.sizecalculation(size: image.size)

                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.imageView.image = image
                   
                    self.imageView.frame = CGRect(x: 0, y: voiceHeight, width: size.width, height: size.height)
                    self.preferredContentSize = .init(width: size.width, height: size.height + voiceHeight)
                }
            } else {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.preferredContentSize = CGSize(width: self.view.bounds.width, height: voiceHeight)
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
        tipsView.text = text
        tipsView.frame = CGRect(x: 0, y: voiceHeight,
                                     width: view.bounds.width,
                                     height: 35)
        view.addSubview(tipsView)
        imageView.frame = CGRect(x: 0,
                                      y: voiceHeight + 35,
                                      width: imageView.bounds.width,
                                      height: imageView.bounds.height)
        
        preferredContentSize = contentSize
        
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


}


extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}
