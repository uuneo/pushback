//
//  File name:     AudioManager.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/10.
	

import Foundation
import AudioToolbox
import AVFAudio
import AVFoundation


class AudioManager: ObservableObject{

	static let shared = AudioManager()
	private var manager = FileManager.default


	private init() {
		self.getFileList()
	}


	@Published var defaultSounds:[URL] =  []
	@Published var customSounds:[URL] =  []

	@Published var soundID: SystemSoundID = 0
	@Published var playingAudio:URL? = nil

	// MARK: - Get audio folder data

	private func getFileList() {
		let defaultSounds:[URL] = {
			var temurl = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) ?? []
			temurl.sort { u1, u2 -> Bool in
				u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
			}
			return temurl
		}()

		let customSounds: [URL] = {
            guard let soundsDirectoryUrl = BaseConfig.getSoundsGroupDirectory() else { return []}

			var urlemp = self.getFilesInDirectory(directory: soundsDirectoryUrl.path(), suffix: "caf")
			urlemp.sort { u1, u2 -> Bool in
				u1.lastPathComponent.localizedStandardCompare(u2.lastPathComponent) == ComparisonResult.orderedAscending
			}

			return urlemp
		}()

		DispatchQueue.main.async {
			self.customSounds = customSounds
			self.defaultSounds = defaultSounds
		}

	}

	/// 返回指定文件夹，指定后缀的文件列表数组
	func getFilesInDirectory(directory: String, suffix: String) -> [URL] {

		do {
			let files = try manager.contentsOfDirectory(atPath: directory)
			return files.compactMap { file -> URL? in
                if file.hasSuffix(suffix), !file.hasPrefix(BaseConfig.longSoundPrefix) {
					return URL(fileURLWithPath: directory).appendingPathComponent(file)
				}
				return nil
			}
		} catch {
			return []
		}
	}


	/// 通用文件保存方法
	func saveSound(url sourceUrl: URL, name lastPath: String? = nil) {
		guard let groupDirectoryUrl = BaseConfig.getSoundsGroupDirectory() else  { return }


		let  groupDestinationUrl = groupDirectoryUrl.appendingPathComponent(lastPath ?? sourceUrl.lastPathComponent )


		if manager.fileExists(atPath: groupDestinationUrl.path) {
			try? manager.removeItem(at: groupDestinationUrl)
		}
        
		do{
			try manager.copyItem(at: sourceUrl, to: groupDestinationUrl)
			Toast.success(title: String(localized: "保存成功"))
		}catch{
			Toast.error(title: error.localizedDescription)
		}


		getFileList()
	}

	func deleteSound(url: URL) {
        guard let soundsDirectoryUrl = BaseConfig.getSoundsGroupDirectory() else { return }
        
		// 删除sounds目录铃声文件
		try? manager.removeItem(at: url)
		// 删除共享目录中的文件
        let groupSoundUrl = soundsDirectoryUrl.appendingPathComponent("\(BaseConfig.longSoundPrefix).\(url.lastPathComponent)")
        try? manager.removeItem(at: groupSoundUrl)
        
		getFileList()
	}


	func playAudio(url:URL? = nil){
		AudioServicesDisposeSystemSoundID(self.soundID)

		guard let audio = url ,playingAudio != url else {
			self.playingAudio = nil
			self.soundID = 0
			return
		}
		self.playingAudio = audio
		AudioServicesCreateSystemSoundID(audio as CFURL, &self.soundID)
		AudioServicesPlaySystemSoundWithCompletion(self.soundID) {
			if self.playingAudio == url {
				AudioServicesDisposeSystemSoundID(self.soundID)
				DispatchQueue.main.async{
					self.playingAudio = nil
					self.soundID = 0
				}

			}

		}

	}
    
    func convertAudioToCAF(inputURL: URL, outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        do {
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
        } catch {
            completion(.failure(error))
            return
        }
        
        
        // 创建 AVAsset
        let asset = AVAsset(url: inputURL)
        
        // 创建导出会话
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(NSError(domain: "AudioConversion", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法创建导出会话"])))
            return
        }
        
        // 设置输出文件类型为 CAF
        exportSession.outputFileType = .caf
        exportSession.outputURL = outputURL
        
        // 执行导出
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed:
                if let error = exportSession.error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "AudioConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "导出失败，原因未知"])))
                }
            case .cancelled:
                completion(.failure(NSError(domain: "AudioConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: "导出被取消"])))
            default:
                break
            }
        }
    }
}



