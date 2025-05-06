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

    private let progressView = UIProgressView(progressViewStyle: .default)
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    private var timer: Timer?
    
    var audioPlayer: AVAudioPlayer? {
        didSet {
            if let player = audioPlayer {
                durationLabel.text = formatTime(player.duration)
                progressView.progress = 0
                currentTimeLabel.text = "0:00"
                startTimer()
                if Defaults[.voicesAutoSpeak]{
                    playPauseTapped()
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
        // 时间标签
        currentTimeLabel.font = .systemFont(ofSize: 12)
        currentTimeLabel.textColor = .gray
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.textColor = .gray

        // 播放进度条
        progressView.trackTintColor = UIColor.systemGray5
        progressView.tintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleProgressTap(_:)))
        progressView.addGestureRecognizer(tapGesture)

        // 播放暂停按钮
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)

        // 停止按钮
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        // 布局
        let hStack = UIStackView(arrangedSubviews: [currentTimeLabel, progressView, durationLabel])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center

        let controlStack = UIStackView(arrangedSubviews: [playPauseButton, stopButton])
        controlStack.axis = .horizontal
        controlStack.spacing = 20
        controlStack.alignment = .center

        let vStack = UIStackView(arrangedSubviews: [hStack, controlStack])
        vStack.axis = .horizontal
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    @objc private func handleProgressTap(_ gesture: UITapGestureRecognizer) {
        guard let player = audioPlayer else { return }
        let location = gesture.location(in: progressView)
        let ratio = max(0, min(location.x / progressView.bounds.width, 1))
        player.currentTime = player.duration * Double(ratio)
        progressView.progress = Float(ratio)
        player.play()
    }

    @objc private func playPauseTapped() {
        guard let player = audioPlayer else { return }

        if player.isPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startTimer()
        }
    }

    @objc private func stopTapped() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        progressView.progress = 0
        currentTimeLabel.text = "0:00"
        timer?.invalidate()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateUI), userInfo: nil, repeats: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        timer?.invalidate()
        progressView.progress = 0
        currentTimeLabel.text = "0:00"
    }

    @objc private func updateUI() {
        guard let player = audioPlayer else { return }
        currentTimeLabel.text = formatTime(player.currentTime)
        progressView.progress = Float(player.currentTime / player.duration)
        
        if !player.isPlaying {
            stopTapped() // 自动重置状态
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
