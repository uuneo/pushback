//
//  File name:     ImageHeroKey.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/17.
	

import SwiftUI


struct ImageHeroKey: PreferenceKey {
	static var defaultValue: [String: Anchor<CGRect>] = [:]
	static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
		value.merge(nextValue()) { $1 }
	}
}

