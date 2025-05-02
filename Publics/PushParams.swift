//
//  PushParams.swift
//  pushback
//
//  Created by lynn on 2025/3/31.
//



enum Params: String, CaseIterable{
    case ciphertext
    case ttl
    case title
    case subtitle
    case body
    case icon
    case image
    case from
    case host
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
    case calstartdate
    case calenddate
    case caltitle
    case calcolor
    case calminutes
    case id
    case category
    
    case callback

    var name:String{ self.rawValue }
}

