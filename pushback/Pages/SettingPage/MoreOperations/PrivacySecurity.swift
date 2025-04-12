//
//  PrivacySecurity.swift
//  pushback
//
//  Created by lynn on 2025/4/13.
//

import SwiftUI
import Defaults
import RealmSwift
import SwiftyJSON

struct PrivacySecurity:View {
    
   
    @Default(.defaultBrowser) var defaultBrowser
    @Default(.deviceToken) var deviceToken
    @Default(.id) var userID
    
    @EnvironmentObject private var manager:PushbackManager
    
    @State private var showTextAnimation:Bool = false
    @State private var showIdAnimation:Bool = false
    
    @State private var showDeleteAlert:Bool = false
    @State private var resetAppShow:Bool = false
    
    @State private var totalSize:UInt64 = 0
    @State private var cacheSize:UInt64 = 0
   
    
    var body: some View {
        List{
            
          
            
            
            
            Section(header:Text( "设备推送令牌")) {
                Button{
                    if deviceToken != ""{
                        Clipboard.shared.setString(deviceToken)
                        Toast.copy(title: String(localized: "复制成功"))
                        
                    }else{
                        
                        Toast.shared.present(title:  String(localized: "请先注册"), symbol: "questionmark.circle.dashed")
                    }
                    self.showTextAnimation.toggle()
                }label: {
                    HStack{
                        
                        Label {
                            Text( "令牌")
                                .lineLimit(1)
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "key")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary, .tint)
                        }
                        
                        
                        Spacer()
                        HackerTextView(text: maskString(deviceToken), trigger:showTextAnimation)
                            .foregroundStyle(.gray)
                            
                        Image(systemName: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .scaleEffect(0.9)
                    }
                }
                
                 Button{
                    Clipboard.shared.setString(userID)
                    Toast.copy(title: String(localized: "复制成功"))
                    self.showIdAnimation.toggle()
                }label: {
                    HStack{
                        
                        Label {
                            Text( "ID")
                                .lineLimit(1)
                                .foregroundStyle(.textBlack)
                        } icon: {
                            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                                .scaleEffect(0.9)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary, .tint)
                        }
                        
                        
                        Spacer()
                        HackerTextView(text: maskString(userID,isID: true), trigger: showIdAnimation)
                            .foregroundStyle(.gray)
                            
                        Image(systemName: "doc.on.doc")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                            .scaleEffect(0.9)
                    }
                }
               
            }
            
            Section(header: Text("端到端加密")){
                
                NavigationLink{
                    CryptoConfigView()
                }label: {
                    Label {
                        Text( "算法配置")
                    } icon: {
                        Image(systemName: "bolt.shield")
                            .scaleEffect(0.9)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                            .symbolEffect(.pulse, delay: 5)
                    }
                }
            }
            
            Section(header: Text("默认浏览器设置")){
                HStack{
                    Picker(selection: $defaultBrowser) {
                        ForEach(DefaultBrowserModel.allCases, id: \.self) { item in
                            Text(item.title)
                                .tag(item)
                        }
                    }label:{
                        Text("默认浏览器")
                    }.pickerStyle(SegmentedPickerStyle())

                }
            }
            
           
            

            Section(header: Text("缓存大小限制")){

                HStack{
                    Label {
                        Text("存储使用")
                    } icon: {
                        Image(systemName: "externaldrive.badge.person.crop")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .symbolEffect(.pulse, delay: 3)
                    }
                    Spacer()
                    
                    Text(totalSize.fileSize())
                        .onAppear{
                            calculateSize()
                        }
                    
                    
                }


                HStack{
                    Button{
                        self.showDeleteAlert.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text(cacheSize.fileSize())
                                .padding(.horizontal, 3)
                            Text("清空缓存")
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                           
                            Spacer()
                        }

                    }.buttonStyle(BorderedProminentButtonStyle())
                        .disabled(cacheSize == 0)

                }
                
                HStack{
                    Button{
                        self.resetAppShow.toggle()
                    }label: {
                        HStack{
                            Spacer()
                            Text("初始化App")
                                .fontWeight(.bold)
                                .padding(.vertical, 5)
                           
                            Spacer()
                        }
                        

                    }
                    .tint(.red)
                    .buttonStyle(BorderedProminentButtonStyle())

                }
                
                
           

            }

           
            
           
        }.navigationTitle("隐私与安全")
            .if(resetAppShow){ view in
                view
                    .alert(isPresented: $resetAppShow) {
                        Alert(title: Text("危险操作!!! 恢复初始化."),
                              message:  Text("将丢失所有数据"),
                              primaryButton: .destructive(Text("确定"), action: { resetApp() }),
                              secondaryButton: .cancel()
                        )}
            }
            .if(showDeleteAlert){ view in
                view
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(title: Text("是否确定清空?"),  message: Text("删除后不能还原!!!"),
                              primaryButton: .destructive(Text("清空"),
                                                          action: {
                            if let cache = ImageManager.defaultCache(),
                               let imageCache = ImageManager.defaultCache(mode: .image),
                               let fileUrl = BaseConfig.getSoundsGroupDirectory(){
                                cache.clearDiskCache()
                                imageCache.clearDiskCache()
                                manager.clearContentsOfDirectory(at: fileUrl)
                                Defaults[.imageSaves] = []
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    calculateSize()
                                }
                                Toast.success(title: String(localized: "清理成功"))
                            }
                            
                        }),
                              secondaryButton: .cancel())
                        
                    }
                
            }
        
    }
    
    func calculateSize(){
        if let group = CONTAINER,
           let soundsUrl = BaseConfig.getSoundsGroupDirectory(),
           let imageUrl = BaseConfig.getImagesDirectory(){
            self.totalSize = manager.calculateDirectorySize(at: group)
            
            self.cacheSize =  manager.calculateDirectorySize(at: soundsUrl) +  manager.calculateDirectorySize(at: imageUrl)
        }
    }
    
    
    fileprivate func resetApp(){
        if let group = CONTAINER{
            manager.clearContentsOfDirectory(at: group)
            exit(0)
        }
        
    }
   

    
    fileprivate func maskString(_ str: String, isID:Bool = false) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) +  str }
        if isID{
            return String(repeating: "*", count: 3) + str.suffix(9)
        }else{
            return str.prefix(3) + String(repeating: "*", count: 5) + str.suffix(6)
        }
       
    }
    
    
}
