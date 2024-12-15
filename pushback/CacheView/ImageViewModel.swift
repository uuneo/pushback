//
//  File name:     ImageViewModel.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/17.
import SwiftUI

struct imageItem: Identifiable, Hashable {
	var id: String = UUID().uuidString
	var title: String
	var image: UIImage?
	var previewImage: UIImage?
	var appeared: Bool = false
}

var sampleItems: [imageItem] = [
	.init(title: "Fanny Hagan", image: UIImage(named: "logo")),
	.init(title: "Fanny Hagan", image: UIImage(named: "logo1")),
	.init(title: "Fanny Hagan", image: UIImage(named: "logo2")),
]
