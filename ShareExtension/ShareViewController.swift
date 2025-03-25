//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by lynn on 2025/3/18.
//

import UIKit
import Social
import SwiftUI
import UniformTypeIdentifiers
import CloudKit

class ShareViewController: UIViewController  {
    
    
    override func viewDidLoad() {
        if let itemProviders = (extensionContext!.inputItems.first as? NSExtensionItem)?.attachments {
            let hostingView = UIHostingController(rootView: ShareView(itemProviders: itemProviders, extensionContext: extensionContext, view: view))
            hostingView.view.frame = view.frame
            
            view.addSubview(hostingView.view)
        }
    }
    
    
    
    func openHostApp(localKey:String) {
        var responder: UIResponder? = self // 从当前对象开始
        
        while let currentResponder = responder {
            // 检查是否是 UIApplication 类型
            if let app = currentResponder as? UIApplication{
                app.open(URL(string: "mw://fromLocalImage?key=\(localKey)")!, options: [:]) { success in
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
    var view:UIView
    
    /// View Properties
    @State private var items: [PushIcon] = []
    @State private var isChecking:Bool = false
    
    @State private var tags: [TagModel] = []
    
    
    var tsgsTem:[String]{
        tags.compactMap({$0.value}).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    @FocusState private var nameFocus
    
    @State private var pictureLoading:Bool = false
    
    @State private var pushIcon:PushIcon = .init(name: "", description: [],size: 0, sha256: "")
    
    @State private var isHistory:Bool = false
    
    @State private var tips:String? = nil
    
    @State private var saveOk:Bool = false
    
    @State private var status:Bool = false
    
    @State private var freeCount:Int = 0
    
    var btnTitle:String{
        
        if status {
            return isHistory  ? String(localized: "复制图片KEY") :  String(localized: "上传到云端")
        }else {
            return  String(localized: "iCloud状态检查")
        }
        
    }
    
    var loadingTitle:String{
        if pictureLoading{
            return status ?  String(localized: "正在处理中...") :  String(localized: "iCloud状态检查中...")
        }else {
            return ""
        }
        
    }
    
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
            
            ScrollView{
                
                
                if isHistory {
                    HStack{
                        Text("tips:")
                            .foregroundStyle(.gray)
                        Text("图片数据已存在，可以直接复制使用！")
                        
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
                
                
                HStack(alignment: .bottom){
                    
                    if let item = items.first, let previewImage = item.previewImage{
                        
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100,height: 100)
                            .blur(radius: pictureLoading ? 5 : 0)
                            .overlay {
                                ProgressView()
                                    .opacity(pictureLoading ? 1 : 0)
                                    .tint(.red)
                                    .scaleEffect(2.0)
                                
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(  // 再添加圆角边框
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isHistory ? Color.red : Color.green, lineWidth: 3)
                            )
                            .onAppear{
                                self.pushIcon = item
                            }
                    }
                    VStack{
                        HStack{
                            Spacer()
                            
                            Text("图标额度剩余")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                            
                           
                            
                            Text("\(freeCount)")
                                .foregroundStyle(freeCount < 5 ? .red : .green)
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            
                            Text("张")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                        }
                        .padding(.bottom, 10)
                        Spacer()
                        TextField(text: $pushIcon.name, prompt: Text("输入图片名称"),label: {Text("图片Key")})
                            .focused($nameFocus)
                        
                            .customField(icon: isChecking ? "checkmark.circle.fill" : "checkmark.circle")
                            .onChange(of: nameFocus) { newValue in
                                if !newValue{
                                    
                                }
                            }
                            .padding(.horizontal, 10)
                            .disabled(isHistory)
                    }
                    
                    
                    
                }
                .padding()
                
                TagField(tags: $tags)
                    .padding()
                    .disabled(isHistory)
                    .onChange(of: tags) { newValue in
                        self.pushIcon.description = self.tsgsTem
                    }
                
                
                AngularButton(title: btnTitle,  disable: pictureLoading || !status, loading: loadingTitle){
                    if isHistory{
                        Clipboard.shared.setString(pushIcon.name)
                        self.tips =  String(localized: "复制成功")
                        
                    }else {
                        if items.count == 0{
                            self.tips =  String(localized: "没有图片")
                        }else {
                            if self.freeCount == 0{
                                self.tips = String(localized: "剩余空间不足")
                                return
                            }
                            Task{
                                await saveItems()
                            }
                        }
                        
                    }
                }.padding()
                
                
            }.simultaneousGesture(
                DragGesture()
                    .onEnded{ transform in
                        if transform.translation.height > 50{
                            self.view.endEditing(true)
                        }
                        
                    }
            ).alert(isPresented: Binding(get: {
                tips != nil
            }, set: { value in
                if !value{
                    tips = nil
                }
            })){
                Alert(title: Text("提示"), message: Text(tips ?? ""), dismissButton: .default(Text("ok")){
                    if saveOk{
                        self.dismiss()
                    }
                    
                })
            }
            
        }
        
        .disabled(!status || freeCount == 0)
        .onAppear(perform: {
            extractItems()
            pictureLoading = true
            Task{
                
                let (success, message) = await PushIconCloudManager.shared.checkAccount()
                
                let records = await PushIconCloudManager.shared.queryIconsForMe()
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                    self.freeCount = Defaults[.freeCloudImageCount]  - records.count
                    self.tips = message
                    self.status = success && self.freeCount > 0
                    pictureLoading = false
                }
            }
        })
        
    }
    
    
    func extractItems() {
        guard items.isEmpty else { return }
        
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
                            
                            items.append(.init(id: UUID().uuidString, name: "", description: [], size: pngData.count, sha256: pngData.sha256(), file: tempURL, previewImage: image))
                        }
                    }
                    
                }
            }
        }
    }
    
    
    /// Saving Items to SwiftData
    func saveItems() async  {
        DispatchQueue.main.async {
            self.pictureLoading = true
        }
        let err = await PushIconCloudManager.shared.savePushIconModel(self.pushIcon)
        Log.debug(err.tips)
        
        switch err {
        case .success(_):
            self.saveOk = true
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.tips = err.tips
            self.pictureLoading = false
        }
        
    }
    
    /// Dismissing View
    func dismiss() {
        extensionContext?.completeRequest(returningItems: [])
    }
    
}
