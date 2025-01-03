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
	var url:String
	var image: UIImage?
	var previewImage: UIImage?
	var appeared: Bool = false
}


struct AlertData:Identifiable {
	var id: UUID = UUID()
	var title:String
	var message:String
	var btn:String
	var mode:AlertType
}


enum AlertType{
	case delete
	case save
}
