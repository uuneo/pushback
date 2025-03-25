//
//  CloudIcon.swift
//  pushback
//
//  Created by lynn on 2025/3/18.
//

import SwiftUI
import Defaults
import CloudKit

struct CloudIcon: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager:PushbackManager
    @State private var searchText:String = ""
    
    @State private var icons:[CKRecord] = []

    @State private var loading = false
    
    @State private var selectImage:UIImage?
    @State private var offset: CGSize = .zero
    
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false){
                if icons.count > 0{
                    VStack{
                        TagLayout(alignment: .center, spacing: 10) {
                            ForEach(icons, id: \.recordID){ icon in
                                
                                
                                
                                if let name = icon["name"] as? String{
                                    
                                    
                                    Menu{
                                        Button {
                                            if let icon = icon.toPushIcon() {
                                                withAnimation {
                                                    self.selectImage = icon.previewImage
                                                }
                                               
                                            }else {
                                                Toast.shared.present(title: String(localized: "图片加载失败"), symbol: .error)
                                            }
                                            
                                        }label:{
                                           
                                            Label("查看图标", systemImage: "photo.artframe.circle")
                                        }
                                        
                                        Button {
                                            Clipboard.shared.setString(name)
                                            Toast.shared.present(title: String(localized:"复制成功"), symbol: .error)
                                        }label:{
                                    
                                            Label("复制key", systemImage: "doc.on.doc")
                                        }
                                        
                                        Section{
                                            Button(role: .destructive) {
                                               
                                                PushIconCloudManager.shared.deleteCloudIcon( icon.recordID.recordName) { error in
                                                    if let error{
                                                        Toast.shared.present(title: "\(error.localizedDescription)", symbol: .error)
                                                    }else{
                                                        Toast.shared.present(title: String(localized:"图片删除成功"), symbol: .error)
                                                        if let index = icons.firstIndex(where: {$0.recordID.recordName == icon.recordID.recordName}){
                                                            icons.remove(at: index)
                                                        }
                                                    }
                                                }
                                            }label:{
                                        
                                                Label("删除云图标", systemImage: "trash")
                                            }
                                        }
                                        
                                        
                                    }label:{
                                        TagView(name, .blue, "cursorarrow.click.2")
                                    }
                                       
                                }
                            }
                            
                        }
                       
                    }
                    .padding(.top ,30)
                }
                else {
                    Text("打开 相册 \n 点击图片 > 分享 > 反推 \n 上传到云端")
                        .padding(.top, 50)
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.center)  // 使文字居中
                        .frame(maxWidth: .infinity, alignment: .center)  // 保证在容器中居中
                        .lineSpacing(10)
                        .pressEvents(onRelease: { _ in
                            PushbackManager.openUrl(url: URL(string: "photos-redirect://")!)
                            self.dismiss()
                        })
                }
            }
            .animation(.smooth, value: icons)
            .navigationTitle("云图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        manager.sheetPage = .none
                    }label: {
                        Image(systemName: "x.circle")
                    }
                        
                }
            }
            .overlay{
                if loading {
                    VStack {
                        Spacer()
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(2)
                                .padding()
                            Text("加载中...")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(width: UIScreen.main.bounds.width)
                                
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        Spacer()
                    }
                }
            }
            .overlay {
                if let selectImage = selectImage{
                    Image(uiImage: selectImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(height: 300)
                        .padding(.horizontal)
                        .transition(.slide)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Update the offset as the user drags the image
                                    withAnimation {
                                        self.offset = value.translation
                                    }
                                   
                                }
                                .onEnded { value in
                                    // Check if the drag distance is greater than 50 points in any direction
                                    if abs(value.translation.width) > 50 || abs(value.translation.height) > 50 {
                                        // If the drag distance exceeds 50 points, hide the image
                                        withAnimation {
                                            self.selectImage = nil
                                        }
                                    }
                                    
                                    withAnimation {
                                        self.offset = .zero
                                    }
                                }
                        )
                }
            }
            .onAppear{
                withAnimation {
                    self.loading = true
                }
                getIcons()
                
            }
        }
    }
    
    func getIcons(){
        Task{
            let icons = await PushIconCloudManager.shared.queryIconsForMe()
            await MainActor.run {
                withAnimation {
                    self.icons = icons
                    self.loading = false
                }
            }
        }
    }
            
    /// Tag View
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)
            
            Image(systemName: icon)
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color.gradient)
        }
    }
}
