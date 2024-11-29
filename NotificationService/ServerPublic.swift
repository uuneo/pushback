//
//  ServerPublic.swift
//  pushback
//
//  Created by He Cho on 2024/11/23.
//



enum Params: String, CaseIterable{
	case ciphertext
	case isarchive
	case title
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
