//
//  ShareSheet.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
	let fileUrl: MessageExportJson
    let applicationActivities: [UIActivity]? = nil

    
	func makeUIViewController(context: Context) -> UIActivityViewController {
        
        let viewController = UIActivityViewController(activityItems:[fileUrl],applicationActivities: applicationActivities)
        
        return viewController
	
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
	
}

