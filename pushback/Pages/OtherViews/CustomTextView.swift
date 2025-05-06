//
//  CustomTextView.swift
//  pushback
//
//  Created by lynn on 2025/5/5.
//

import SwiftUI
import UIKit


struct PText: UIViewRepresentable {
    var text: String
    var size: CGFloat
    var weight: UIFont.Weight
    var highlight:String?
    init(_ text: String,highlight:String? = nil , size: CGFloat = 17, weight: UIFont.Weight = .regular) {
        self.text = text
        self.size = size
        self.weight = weight
        self.highlight = highlight
    }
    
    
    func makeUIView(context: Context) -> CustomTapTextView{
        let textField = CustomTapTextView()
        textField.font = UIFont.preferredFont(ofSize: size, weight: weight)
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }

    func updateUIView(_ uiView: CustomTapTextView, context: Context) {
        
        let attributed = NSMutableAttributedString(string: text)
        let font = UIFont.preferredFont(ofSize: size, weight: weight)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.font, value: font, range: fullRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.textBlack, range: fullRange) // 默认颜色

        if let keyword = highlight, !keyword.isEmpty {
            let pattern = NSRegularExpression.escapedPattern(for: keyword)
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: fullRange)
                for match in matches {
                    attributed.addAttribute(.foregroundColor, value: UIColor.systemRed, range: match.range)
                }
            }
        }

        uiView.attributedText = attributed
    }

   
}

/// 可以自定义点击事件的 UITextView，同时保留 UITextView 的所有其他手势
/// 此 TextView  不可编辑， 不可滚动
class CustomTapTextView: UITextView, UIGestureRecognizerDelegate {
    /// 点击手势，如果有选中文字，则不触发
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
    /// 双击手势，只是为了让 tapGesture 不要在双击选中文本时触发，没有其他作用
    private let doubleTapGesture = UITapGestureRecognizer()
    /// UITextView 自带的点击链接手势
    private var linkTapGesture: UIGestureRecognizer? = nil
    
    /// 额外的单击事件
    var customTapAction: (() -> Void)?
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        
        self.backgroundColor = UIColor.clear
        self.isEditable = false
        self.isScrollEnabled = false
        self.dataDetectorTypes = [.phoneNumber, .link]
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byWordWrapping
        self.textContainer.widthTracksTextView = true
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        
        self.linkTapGesture = self.gestureRecognizers?.first {
            $0 is UITapGestureRecognizer && $0.name == "UITextInteractionNameLinkTap"
        }
        
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        self.addGestureRecognizer(doubleTapGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tap() {
        self.customTapAction?()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == doubleTapGesture {
            return true
        }
        return false
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture {
            if self.selectedRange.length > 0 {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapGesture {
            if otherGestureRecognizer == doubleTapGesture {
                return true
            }
            if otherGestureRecognizer == linkTapGesture {
                return true
            }
        }
        return false
    }
    
  
}



extension UIFont {
    class func preferredFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        return UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: size, weight: weight))
    }
}
