//
//  Application+.swift
//  pushme
//
//  Created by lynn on 2025/6/5.
//

import UIKit
import SwiftUI


extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
    }
}


extension UIApplication {
    var currentKeyWindow: UIWindow? {
        return self.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    var topSafeAreaHeight: CGFloat {
        self.currentKeyWindow?.safeAreaInsets.top ?? 50
    }
}

// MARK: -  keyPath+.swift
func == <T, Value: Equatable>( keyPath: KeyPath<T, Value>, value: Value) -> (T) -> Bool {
    { $0[keyPath: keyPath] == value }
}
