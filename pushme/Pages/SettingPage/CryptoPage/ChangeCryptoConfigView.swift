//
//  AddCryptoConfigView.swift
//  pushme
//
//  Created by lynn on 2025/8/3.
//
import SwiftUI
import Defaults

struct ChangeCryptoConfigView: View {
    
    var item: CryptoModelConfig
    
    @State var cryptoConfig = CryptoModelConfig(algorithm: .AES256, mode: .GCM, key: "", iv: "")
    
    var expectKeyLength:Int {  cryptoConfig.algorithm.rawValue }

    @Environment(\.dismiss) var dismiss
    @FocusState private var keyFocus
    @FocusState private var ivFocus
    
    @State private var sharkText:String = ""
    @FocusState private var sharkfocused:Bool
    @State private var success:Bool = false
    @Default(.cryptoConfigs) var cryptoConfigs
    var title:String{
        return cryptoConfigs.contains(item) ? String(localized: "修改配置") : String(localized: "新增配置")
    }
    
    
    var body: some View {
        
        NavigationStack{
            Form {
                Section{
                    
                    TextEditor(text: $sharkText)
                        .overlay{
                            if !success {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray,  lineWidth: 2)
                            }
                        }
                        .focused($sharkfocused)
                        .overlay{
                            if sharkText.isEmpty{
                                Text("粘贴到此处,自动识别")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .overlay{
                            if success{
                                ColoredBorder(cornerRadius: 10,padding: 0)
                            }
                        }
                        .frame(maxHeight: 150)
                        .onChange(of: sharkfocused) { value in
                            
                            guard !value else { return }
                            
                            let data = AppManager.shared.outParamsHandler(address: sharkText)
                            var result:String{
                                switch data {
                                case .text(let string): string
                                case .crypto(let string): string
                                default: ""
                                }
                            }
                            if let config = CryptoModelConfig(inputText: result){
                                cryptoConfig = config
                                self.success = true
                            }else{
                                self.success = false
                                self.sharkText = ""
                            }
                        }
                    
                }header: {
                    Text("导入配置")
                }
                Section{
                    
                    Picker(selection: $cryptoConfig.algorithm) {
                        ForEach(CryptoAlgorithm.allCases,id: \.self){item in
                            Text(item.name).tag(item)
                        }
                    } label: {
                        Label( "算法", systemImage: cryptoConfig.algorithm.Icon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                    }

                }header:{
                    Text("选择加密算法")
                        .textCase(.none)
                }
                
                
                
                
                Section {
                    
                    Picker(selection: $cryptoConfig.mode) {
                        ForEach(CryptoMode.allCases,id: \.self){item in
                            Text(item.rawValue).tag(item)
                        }
                    } label: {
                        Label("模式", systemImage: cryptoConfig.mode.Icon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( .tint, Color.primary)
                    }
                }
                
                Section {
                    
                    HStack{
                        Label {
                            Text("Padding:")
                        } icon: {
                            Image(systemName: "p.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle( Color.primary, .tint)
                        }
                        Spacer()
                        Text(cryptoConfig.mode.padding)
                            .foregroundStyle(.gray)
                    }
                    
                }
                
                Section {
                    
                    
                    HStack{
                        Label {
                            Text("Iv：")
                        } icon: {
                            Image(systemName: "dice")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(cryptoConfig.iv.count != 16 ? .red : .accent,
                                                 cryptoConfig.iv.count != 16 ? .red : Color.primary)
                            
                        }
                        Spacer()
                        TextField("请输入16位Iv",text: $cryptoConfig.iv)
                            .focused($ivFocus)
                        
                    }
                    
                    HStack{
                        Label {
                            Text("Key:")
                        } icon: {
                            Image(systemName: "key")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle( cryptoConfig.key.count == expectKeyLength ? Color.primary : .red,
                                                  cryptoConfig.key.count == expectKeyLength ? Color.accent : .red)
                        }
                        Spacer()
                        
                        
                        TextField(String(format: String(localized: "输入%d位数的key"), expectKeyLength),text: $cryptoConfig.key)
                            .focused($keyFocus)
                        
                        
                    }
                    
                }header:{
                    
                    Button {
                        cryptoConfig.iv = CryptoModelConfig.generateRandomString()
                        cryptoConfig.key = CryptoModelConfig.generateRandomString(cryptoConfig.algorithm.rawValue)
                        Haptic.impact()
                    } label: {
                        Label("随机生成密钥", systemImage: "dice")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.green, Color.primary)
                            .textCase(.none)
                        
                    }
                }
                
                Section{
                    AngularButton(title: "保存",  loading: ""){
                        if cryptoConfig.iv.count != 16  || cryptoConfig.key.count != expectKeyLength{
                            Toast.error(title: "参数长度不正确")
                            return
                            
                        }
                        
                        if let index = Defaults[.cryptoConfigs].firstIndex(where: {$0 == cryptoConfig}){
                            Defaults[.cryptoConfigs][index] = cryptoConfig
                        }else{
                            Defaults[.cryptoConfigs].append(cryptoConfig)
                        }
                        
                        self.dismiss()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle( title )
            .toolbar{
                
                ToolbarItemGroup(placement: .keyboard) {
                    Button("清除") {
                        if keyFocus {
                            cryptoConfig.key = ""
                        }else if ivFocus{
                            cryptoConfig.iv = ""
                        }
                    }
                    Spacer()
                    Button( "完成") {
                        self.hideKeyboard()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        self.dismiss()
                    }label:{
                        Label("关闭", systemImage: "xmark")
                    }.tint(.red)
                }
                
                
            }
            .onAppear{
                self.cryptoConfig = item
            }
        }
        
    }
    
}
