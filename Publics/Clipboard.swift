import UniformTypeIdentifiers
import UIKit


class Clipboard {

    class func set(_ message: String? = nil, _ items:[String : Any]...) {
        var result:[[String:Any]] = []
        
        if let message { result.append([UTType.utf8PlainText.identifier: message]) }
        
        UIPasteboard.general.items = result + items
    }
    
    class func getText() -> String? {
        UIPasteboard.general.string
    }
    
    class func getNSAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()

        for item in UIPasteboard.general.items {
            for (type, value) in item {
                if type == "public.rtf", let data = value as? Data {
                    if let attrStr = try? NSAttributedString(data: data, options: [
                        .documentType: NSAttributedString.DocumentType.rtf
                    ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type == "public.html", let htmlString = value as? String {
                    if let data = htmlString.data(using: .utf8),
                       let attrStr = try? NSAttributedString(data: data, options: [
                           .documentType: NSAttributedString.DocumentType.html,
                           .characterEncoding: String.Encoding.utf8.rawValue
                       ], documentAttributes: nil) {
                        result.append(attrStr)
                    }
                } else if type.hasPrefix("public.image"), let image = value as? UIImage {
                    let attachment = NSTextAttachment()
                    attachment.image = image
                    let imageAttrStr = NSAttributedString(attachment: attachment)
                    result.append(imageAttrStr)
                } else if type == "public.utf8-plain-text", let text = value as? String {
                    let textAttrStr = NSAttributedString(string: text)
                    result.append(textAttrStr)
                }
            }
        }

        return result
    }

}



