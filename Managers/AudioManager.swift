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
			guard let soundsDirectoryUrl = BaseConfig.getSoundslibraryDirectory() else { return []}

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
				if file.hasSuffix(suffix) {
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
		guard let groupDirectoryUrl = BaseConfig.getSoundsGroupDirectory(),
			  let libraryDirectoryUrl = BaseConfig.getSoundslibraryDirectory()
		else  {
			return
		}


		let  groupDestinationUrl = groupDirectoryUrl.appendingPathComponent(lastPath ?? sourceUrl.lastPathComponent )

		let  libraryDestinationUrl = libraryDirectoryUrl.appendingPathComponent(lastPath ?? sourceUrl.lastPathComponent )


		if manager.fileExists(atPath: groupDestinationUrl.path) {
			try? manager.removeItem(at: groupDestinationUrl)
		}
		if manager.fileExists(atPath: libraryDestinationUrl.path) {
			try? manager.removeItem(at: libraryDestinationUrl)
		}

		do{
			try manager.copyItem(at: sourceUrl, to: groupDestinationUrl)
			try manager.copyItem(at: sourceUrl, to: libraryDestinationUrl)
			Toast.shared.present(title: String(localized: "保存成功"), symbol: .success)
		}catch{
			Toast.shared.present(title: error.localizedDescription, symbol: .error)
		}


		getFileList()
	}

	func deleteSound(url: URL) {
		// 删除sounds目录铃声文件
		try? manager.removeItem(at: url)
		// 删除共享目录中的文件
		if let groupSoundUrl = BaseConfig.getSoundsGroupDirectory()?.appendingPathComponent(url.lastPathComponent) {
			try? manager.removeItem(at: groupSoundUrl)
		}
		getFileList()
	}


	func playAudio(url:URL? = nil){
		AudioServicesDisposeSystemSoundID(self.soundID)
		guard let audio = url else {
			return
		}
		DispatchQueue.main.async{
			self.playingAudio = audio
			AudioServicesCreateSystemSoundID(audio as CFURL, &self.soundID)
			AudioServicesPlaySystemSoundWithCompletion(self.soundID) {
				AudioServicesDisposeSystemSoundID(self.soundID)
				DispatchQueue.main.async{
					self.playingAudio = nil
				}
			}
		}


	}


}
