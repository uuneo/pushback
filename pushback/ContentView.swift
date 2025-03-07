//
//  File name:     ContentView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/24.


import SwiftUI

struct ContentView: View {
 
    var body: some View {
        
        ZStack{
            TabPageView()
                .environmentObject(PushbackManager.shared)
        }
    }
    
}



#Preview {
    TabPageView()
        .environmentObject(PushbackManager.shared)
}
