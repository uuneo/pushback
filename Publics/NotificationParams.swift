//
//  File name:     NotificationParams.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/24.
	

enum Params: String, CaseIterable{
	case ciphertext
	case ttl
	case title
	case subtitle
	case body
	case icon
	case image
	case from
	case video
	case group
	case sound
	case badge
	case call
	case mode
	case url

	case iv
	case aps
	case alert
	case caf


	case autocopy
	case copy

	var name:String{ self.rawValue }
}
