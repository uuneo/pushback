//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by He Cho on 2024/10/26.
//

import UIKit
import AVKit
import CoreMotion
import UserNotifications
import UserNotificationsUI



class NotificationViewController: UIViewController, UNNotificationContentExtension {
	
	
	@IBOutlet weak var loadingView:UIActivityIndicatorView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var videoPlayerView: UIView!
	
	var player: AVPlayer?
	var playPauseButton: UIButton?
	

	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.imageView.contentMode = .scaleAspectFit
		// 添加点击手势识别器到视频播放视图
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoPlayerViewTapped))
		self.videoPlayerView.addGestureRecognizer(tapGesture)
		
		self.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: 50)
		
		setupLoading()
	   
	}
	
	
	func setupLoading(){
		loadingView.sizeToFit()
		loadingView.color = .green
		loadingView.hidesWhenStopped = true
		loadingView.style = .large
		
		// 禁用自动调整子视图大小
		loadingView.translatesAutoresizingMaskIntoConstraints = false
		
		// 设置 loadingView 的约束
		NSLayoutConstraint.activate([
			loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		
	}
	
	
	func didReceive(_ notification: UNNotification) {
		let userInfo = notification.request.content.userInfo
		
		if userInfo["autocopy"] as? String == "1" || userInfo["automaticallycopy"] as? String == "1" {
			if let copy = userInfo["copy"] as? String {
				UIPasteboard.general.string = copy
			} else {
				UIPasteboard.general.string = notification.request.content.body
			}
		}
		
		if let videoUrl = userInfo["video"] as? String, let videoUrl = URL(string: videoUrl) {
			VideoHandler(videoUrl: videoUrl)
		} else if let imageUrl = userInfo["image"] as? String {
			ImageHandler(imageUrl: imageUrl)
		} else {
			self.preferredContentSize = CGSize(width: self.view.frame.width, height: 1)
		}
	}
	
	func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
		let userInfo = response.notification.request.content.userInfo
		
		switch response.actionIdentifier {
		case Identifiers.detailAction:
			completion(.dismissAndForwardAction)
		case Identifiers.copyAction:
			if let copy = userInfo["copy"] as? String {
				UIPasteboard.general.string = copy
			} else {
				UIPasteboard.general.string = response.notification.request.content.body
			}
			completion(.dismiss)
		default:
			completion(.dismiss)
		}
	}
	
   
	
	func ImageHandler(imageUrl: String) {
		self.videoPlayerView.frame = .zero
		loadingView?.startAnimating()
		Task.detached(priority: .high) {
			if let imageFileUrl = await ImageManager.fetchImage(from: imageUrl),
			   let image = UIImage(contentsOfFile: imageFileUrl) {
				
				let size = await self.sizecalculation(size: image.size)
				
				await MainActor.run { [weak self] in
					guard let self = self else { return }
					
					self.loadingView.stopAnimating()
					self.imageView.image = image
					self.preferredContentSize = size
					self.imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
				}
			} else {
				await MainActor.run { [weak self] in
					guard let self = self else { return }
					
					self.preferredContentSize = .zero
					self.loadingView.stopAnimating()
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
}

extension NotificationViewController{
	func VideoHandler(videoUrl: URL) {
		self.imageView.frame = .zero
		
		// 显示加载视图
		loadingView?.startAnimating()
		
		let player = AVPlayer(url: videoUrl)
		self.player = player
		let playerLayer = AVPlayerLayer(player: player)
		playerLayer.videoGravity = .resizeAspect
		player.actionAtItemEnd = .pause
		
		let asset = AVURLAsset(url: videoUrl)
		
		// 异步加载视频轨道
		asset.loadTracks(withMediaType: .video) { tracks, error in
			guard let videoTrack = tracks?.first else {
				print("加载视频轨道时出错: \(String(describing: error))")
				return
			}
			
			// 使用 Task 来异步加载视频的自然尺寸
			Task.detached(priority: .high) {
				do {
					let videoSize: CGSize = try await videoTrack.load(.naturalSize)
					let videoAspectRatio = videoSize.width / videoSize.height
					
					// 根据视频的宽高比计算新的高度
					let newHeight = await self.view.bounds.width / videoAspectRatio
					let playerLayerFrame = await CGRect(x: 0, y: 0, width: self.view.bounds.width, height: newHeight)
					
					// 在主线程上更新 playerLayer 并确保它居中
					await MainActor.run { [weak self] in
						guard let self = self else { return }
						self.preferredContentSize = CGSize(width: self.view.bounds.width, height: newHeight)
						self.videoPlayerView.frame = playerLayerFrame
						playerLayer.frame = self.videoPlayerView.bounds // playerLayer 跟随 videoPlayerView 的 bounds
						
						
						// 视频加载完成后隐藏加载视图
						self.loadingView?.stopAnimating()
						
						self.videoPlayerView.layer.addSublayer(playerLayer)
						
						player.play()
						
						// 添加观察者监听播放完成事件
						NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
						
						// 添加播放/暂停按钮
						self.setupPlayPauseButton()
					}
				   
				} catch {
					print("加载视频自然尺寸时出错: \(error)")
					// 如果加载失败，停止加载指示器
					await MainActor.run {
						self.loadingView?.stopAnimating()
					}
				}
			}
		}
		
	   
	}
	
	func setupPlayPauseButton() {
		// 定义按钮的宽度和高度
		let buttonSize: CGFloat = 60 // 可以根据需求调整大小
		
		// 初始化播放/暂停按钮，放在左下角
		let playPauseButton = UIButton(type: .custom)
		playPauseButton.frame = CGRect(x: 20, y: self.videoPlayerView.bounds.height - buttonSize - 20, width: buttonSize, height: buttonSize)
		
		if let image = UIImage(systemName: "play.circle.fill") {
			let resizedImage = image.withConfiguration(UIImage.SymbolConfiguration(pointSize: buttonSize * 0.8, weight: .bold))
			playPauseButton.setImage(resizedImage, for: .normal)
		}
		
		playPauseButton.isHidden = true
		
		playPauseButton.tintColor = .white
		
		// 绑定点击事件
		playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped(_:)), for: .touchUpInside)
		
		
		// 将按钮添加到视频视图
		self.videoPlayerView.addSubview(playPauseButton)
		self.playPauseButton = playPauseButton
	}
	
	func togglePlayPause() {
		guard let player = self.player else { return }
		guard let button = self.playPauseButton else { return }
		
		if player.timeControlStatus == .playing {
			player.pause()
			button.isHidden = false // 暂停时显示播放按钮
		} else {
			player.play()
			button.isHidden = true // 播放时隐藏按钮
		}
	}

	@objc func playPauseButtonTapped(_ sender: UIButton) {
		togglePlayPause()
	}

	@objc func videoPlayerViewTapped() {
		togglePlayPause()
	}
	
	@objc func playerDidFinishPlaying() {
		guard let player = self.player else { return }
		player.seek(to: .zero) // 将视频进度重置为开头
		self.playPauseButton?.isHidden = false // 显示按钮
	}
	
}


