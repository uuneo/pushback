//
//  SFSafariView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//

import SafariServices
import UIKit
import SwiftUI




class PushbackSafariViewController: SFSafariViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .default
	}
	
	
	deinit {
		Task {
			await SFSafariViewController.DataStore.default.clearWebsiteData()
		}
	}
	
	
}



struct SFSafariView: UIViewControllerRepresentable {
	let url: String

	func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
		let requestUrl:URL = URL(string: url) ?? URL(string: BaseConfig.problemWebUrl)!
		
		
		let sfVC =  SFSafariViewController(url: requestUrl)
//        sfVC.preferredBarTintColor = .blue // set color to tint the background of the navigation bar and the toolbar.
//        sfVC.preferredControlTintColor = .yellow // set the color to tint the control buttons on the navigation bar and the toolbar.
		
		return sfVC
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariView>) {
		return
	}
	
	
	

}
