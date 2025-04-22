//
//  MessageData.swift
//  pushback
//
//  Created by lynn on 2025/4/25.
//

import SwiftUI
import RealmSwift

class MessagesData:ObservableObject{
    
    @Published var messages:[Message] = []
    @Published var groups:[Message] = []
    
    
    
}
