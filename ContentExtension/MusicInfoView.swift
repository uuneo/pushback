//
//  MusicInfoView.swift
//  pushback
//
//  Created by lynn on 2025/5/14.
//

import UIKit
import AVFoundation
import Defaults

class MusicInfoView: UIView, AVAudioPlayerDelegate {

    private let progressSlider = UISlider()
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    private var timer: Timer?
    private var isUserSeeking = false

    
    
    var audioPlayer: AVAudioPlayer? {
        didSet {
            if let player = audioPlayer {
                stopButton.setTitle(formatTime(player.duration), for: .normal)
                progressSlider.value = 0
                playPauseButton.setTitle("0:00", for: .normal)
                
                if Defaults[.voicesAutoSpeak]{
                    startTimer()
                    self.playStatue = !player.isPlaying
                }
            }
        }
    }
    
    var text: String? {
        didSet {
            Task {
                guard let text = text else{ return }
                let client = try VoiceManager()
                let filePath = try await client.createVoice(text: text)
                self.audioPlayer = try AVAudioPlayer(contentsOf: filePath)
                self.audioPlayer?.delegate = self
            }
        }
    }
    
    var playStatue:Bool = false{
        didSet{
            if playStatue {
                startTimer()
                audioPlayer?.play()
            }else{
                timer?.invalidate()
                audioPlayer?.pause()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    

    private func setupUI() {
        playPauseButton.setTitle("0.00", for: .normal)
        stopButton.setTitle("0.00", for: .normal)
        // 播放进度滑块
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = .systemOrange
        progressSlider.maximumTrackTintColor = UIColor.systemGray5
        progressSlider.thumbTintColor = .systemOrange
    
        // 假设你有一个名为"logo"的图片资源
        if let originalImage = UIImage(named: "logo") {
            // 1. 调整图片大小
            let size = CGSize(width: 20, height: 20)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            originalImage.draw(in: CGRect(origin: .zero, size: size))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 2. 设置渲染模式并应用颜色
            if let resizedImage = resizedImage {
                let tintedImage = resizedImage.withRenderingMode(.alwaysTemplate)
                    .withTintColor(.systemOrange)
                
                // 3. 将处理后的图片应用到滑块
                progressSlider.setThumbImage(tintedImage, for: .normal)
            }
        }
        progressSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(beginSeeking), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(endSeeking), for: [.touchUpInside, .touchUpOutside])
        progressSlider.isUserInteractionEnabled = true
        
        // 播放暂停按钮
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // 停止按钮
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
    
        // 布局
        let hStack = UIStackView(arrangedSubviews: [playPauseButton, progressSlider, stopButton])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    @objc private func playPauseTapped(_ gesture: UITapGestureRecognizer) {
        guard let player = audioPlayer else { return }
        self.playStatue = !player.isPlaying
    }

    @objc private func stopTapped() {
        
        timer?.invalidate()
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        progressSlider.value = 0
        playPauseButton.setTitle("0:00", for: .normal)
        
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.invalidate()
        progressSlider.value = 0
        playPauseButton.setTitle("0:00", for: .normal)
        
    }

    @objc private func updateUI() {
        guard let player = audioPlayer, !isUserSeeking else { return }
        playPauseButton.setTitle(formatTime(player.currentTime), for: .normal)
        progressSlider.value = Float(player.currentTime / player.duration)
    }
    
    @objc private func beginSeeking() {
        isUserSeeking = true
        audioPlayer?.pause()
        timer?.invalidate()
    }
    
    @objc private func endSeeking() {
        isUserSeeking = false
        guard let player = audioPlayer else { return }
        
        let seekTime = TimeInterval(progressSlider.value) * player.duration
        player.currentTime = seekTime
        playPauseButton.setTitle(formatTime(seekTime), for: .normal)
        
        startTimer()
        player.play()
    }
    
    @objc private func handleSliderChange() {
        guard let player = audioPlayer else { return }
        playPauseButton.setTitle(formatTime(TimeInterval(progressSlider.value) * player.duration), for: .normal)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
