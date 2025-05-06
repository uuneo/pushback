//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by lynn on 2025/4/3.
//

import UIKit
import Social
import SwiftUI
import UniformTypeIdentifiers
import CloudKit

class ShareViewController: UIViewController  {
    
    
    override func viewDidLoad() {
        if let itemProviders = (extensionContext!.inputItems.first as? NSExtensionItem)?.attachments {
            let hostingView = UIHostingController(rootView: ShareView(itemProviders: itemProviders, extensionContext: extensionContext, view: view, openHostApp: openHostApp))
            hostingView.view.frame = view.frame
            
            view.addSubview(hostingView.view)
        }
    }
    
    
    func openHostApp(_ localKey:URL) {
        var responder: UIResponder? = self // 从当前对象开始
        
        while let currentResponder = responder {
            // 检查是否是 UIApplication 类型
            if let app = currentResponder as? UIApplication{
                app.open(localKey, options: [:]) { success in
                    Log.debug("打开app状态：\(success)")
                }
                return
            }
            
            // 遍历下一个响应者
            responder = currentResponder.next
        }
        
        Log.debug("没有找到响应链")
    }
    
    
}

fileprivate struct ShareView: View {
    var itemProviders: [NSItemProvider]
    var extensionContext: NSExtensionContext?
    var view:UIView?
    var openHostApp:(URL)-> Void
    
   
    @State private var pushIcon:PushIcon?


    
    var body: some View {
        VStack{
            Text("iCloud 云图标")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    Button("取消", action: dismiss)
                        .tint(.red)
                }
                .padding()
            
            if let pushIcon{
                UploadIclondIcon(pushIcon: pushIcon) { _ in
                    openHostApp(PBScheme.pb.scheme(host: .openPage, params: ["page" : "icon"]))
                    
                    dismiss()
                } endEditing: {
                    self.view?.endEditing(true)
                }
            }
            

        }
        .onAppear{
            extractItems()
        }
        
        
    }
    
    
    func extractItems() {
        guard pushIcon == nil else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            for provider in itemProviders {
                _ = provider.loadDataRepresentation(for: .image) { data, error in
                    guard let data = data else { return }
                    
                    if let image = data.toThumbnail(max: 300){
                        let tempDir = FileManager.default.temporaryDirectory
                        let tempURL = tempDir.appendingPathComponent("cloudIcon.png")
                        
                        guard let pngData = image.pngData() else { return }
                        
                        do{
                            try pngData.write(to: tempURL)
                        }catch{
                            Log.error(error.localizedDescription)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            
                            self.pushIcon = .init(id: UUID().uuidString, name: "", description: [], size: pngData.count, sha256: pngData.sha256(), file: tempURL, previewImage: image)
                        }
                    }
                    
                }
            }
        }
    }
    
    /// Dismissing View
    func dismiss() {
        extensionContext?.completeRequest(returningItems: [])
    }
    
}
