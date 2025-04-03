
import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(iOS) || os(visionOS)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage
#endif

final class Clipboard: Sendable {
    static let shared = Clipboard()
    
    private init() {} // 防止外部实例化
    
    func setString(_ message: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = message
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message, forType: .string)
        #endif
    }
    
    func getText() -> String? {
        #if os(iOS) || os(visionOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #endif
    }
    
    func getImage() -> PlatformImage? {
        #if os(iOS) || os(visionOS)
        return UIPasteboard.general.image
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        guard let imgData = pasteboard.data(forType: .tiff) else { return nil }
        return NSImage(data: imgData)
        #endif
    }
}
