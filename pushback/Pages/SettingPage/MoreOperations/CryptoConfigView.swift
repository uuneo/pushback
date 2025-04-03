//
//  CryptoConfigView.swift
//  Meow
//
//  Created by uuneo 2024/8/10.
//

import SwiftUI
import Defaults

struct CryptoConfigView: View {
    @Default(.cryptoConfig) var cryptoConfig
    @Default(.servers) var servers
    
    
    @FocusState private var keyFocus
    @FocusState private var ivFocus
    
    var expectKeyLength:Int {
        cryptoConfig.algorithm.rawValue
    }
    
    var labelIcoc:String{
        switch cryptoConfig.algorithm{
        case .AES128: "gauge.low"
        case .AES192: "gauge.medium"
        case .AES256: "gauge.high"
        }
    }
    
    var modeIcon:String{
        switch cryptoConfig.mode{
        case .CBC:
            "circle.grid.cross.left.filled"
        case .ECB:
            "circle.grid.cross.up.filled"
        case .GCM:
            "circle.grid.cross.right.filled"
        }
    }
    
    
    var body: some View {
        
        List {
            
            
            Section{
                Picker(selection: $cryptoConfig.algorithm, label:
                        Label( "算法", systemImage: labelIcoc)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .tint, Color.primary)
                       
                       
                ) {
                    ForEach(CryptoAlgorithm.allCases,id: \.self){item in
                        Text(item.name).tag(item)
                    }
                }
            }header:{
                Text("选择后配置自动保存")
            }
            .onChange(of: cryptoConfig.algorithm) {  _ in
                verifyCopyText()
            }
            
            
            
            
            
            Section {
                Picker(selection: $cryptoConfig.mode, label:
                        Label("模式", systemImage: modeIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle( .tint, Color.primary)
                       
                ) {
                    ForEach(CryptoMode.allCases,id: \.self){item in
                        Text(item.rawValue).tag(item)
                    }
                }
            }
            .onChange(of: cryptoConfig.mode) {  _ in
                verifyCopyText()
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
                        Text("Key:")
                    } icon: {
                        Image(systemName: "key")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( Color.primary, .tint)
                    }
                    Spacer()
                    
                    
                    
                    TextEditor(text: $cryptoConfig.key)
                        .focused($keyFocus)
                        .frame(minHeight: 50)
                        .overlay{
                            if cryptoConfig.key.isEmpty{
                                Text(String(format: String(localized: "输入%d位数的key"), expectKeyLength))
                                
                            }
                        }
                        .onDisappear{
                            let _ = verifyKey()
                        }
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                    
                }
                
                
                
            }
            
            
            Section {
                
                
                HStack{
                    Label {
                        Text("Iv：")
                    } icon: {
                        Image(systemName: "dice")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                        
                    }
                    Spacer()
                    
                    TextEditor(text: $cryptoConfig.iv)
                        .focused($ivFocus)
                        .overlay{
                            if cryptoConfig.iv.isEmpty{
                                Text( "请输入16位Iv")
                                
                            }
                        }
                        .onDisappear{
                            let _ = verifyIv()
                        }
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                    
                    
                    
                }
                
                
            }
            
            
            
            HStack{
                Spacer()
                
                Button {
                    verifyCopyText(false)
                } label: {
                    Label("复制Python脚本", systemImage: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.primary)
                        .padding(.horizontal)
                    
                }.buttonStyle(BorderedProminentButtonStyle())
                Spacer()
            } .listRowBackground(Color.clear)
        }
        .navigationTitle( "算法配置")
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
                    PushbackManager.hideKeyboard()
                }
            }
            
            ToolbarItem {
                
                Button {
                    cryptoConfig.iv = CryptoModel.generateRandomString()
                    cryptoConfig.key = CryptoModel.generateRandomString(cryptoConfig.algorithm.rawValue)
                } label: {
                    Label("随机生成密钥", systemImage: "dice")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .padding(.horizontal)
                    
                }
                
                
            }
        }
        
    }
    func verifyKey(_ showMsg:Bool = true)-> Bool{
        if cryptoConfig.key.count != expectKeyLength{
            cryptoConfig.key = ""
            if showMsg{
                Toast.info(title: String(localized:  "自动更正Key参数"))
            }
            return false
        }
        return true
    }
    
    func verifyIv(_ showMsg:Bool = true) -> Bool{
        if cryptoConfig.iv.count != 16 {
            cryptoConfig.iv = ""
            if showMsg{
                Toast.info(title: String(localized:  "自动更正Iv参数"))
            }
            return false
        }
        return true
    }
    
    
    func verifyCopyText(_ showMsg:Bool = true){
        
        
        if !verifyIv(showMsg) {
            cryptoConfig.iv = CryptoModel.generateRandomString()
        }
        
        if !verifyKey(showMsg){
            cryptoConfig.key = CryptoModel.generateRandomString(cryptoConfig.algorithm.rawValue)
        }
        
        
        if !showMsg{
            Clipboard.shared.setString( cryptoExampleHandler() )
            Toast.copy(title: String(localized:  "复制成功"))
        }
        
    }
    
    func cryptoExampleHandler() -> String {
        let config = Defaults[.cryptoConfig]
        let servers = Defaults[.servers]
        
        let cipher = "AES.new(key, AES.MODE_\(config.mode.rawValue)\(config.mode == .ECB ?  "" : ", iv" ))"
        
        let paddedData = config.mode == .GCM ? "data.encode()" : "pad(data.encode(), AES.block_size)"
        
        let encryptedData = config.mode == .GCM ? "encrypted_data, tag = cipher.encrypt_and_digest(padded_data)" : "encrypted_data = cipher.encrypt(padded_data)"
        
        let encryptedDataReturn = config.mode == .GCM ? "iv + encrypted_data + tag" : "encrypted_data"
        
        let nonce = config.mode == .GCM ? "iv[:12]" : "iv"
        
        return """
 # Documentation: "https://pushback.uuneo.com/#/encryption"
 # python demo: \(String(localized: "使用AES加密数据，并发送到服务器"))
 # pip3 install pycryptodome
 
 import json
 import base64
 import requests
 from Crypto.Cipher import AES
 from Crypto.Util.Padding import pad
 
 def encrypt_aes_mode(data, key, iv):
     cipher = \(cipher)
     padded_data = \(paddedData)
     \(encryptedData)
     return \(encryptedDataReturn)
 
 
 # \(String(localized: "JSON数据"))
 json_string = json.dumps(\(BaseConfig.testData))
 
 # \(String(format: String(localized: "必须%d位"), Int(config.algorithm.name.suffix(3))! / 8))
 key = b"\(config.key)"
 # \(String(localized: "IV可以是随机生成的，但如果是随机的就需要放在 iv 参数里传递。"))
 iv= b"\(config.iv)"
 
 # \(String(localized: "加密"))
 encrypted_data = encrypt_aes_mode(json_string, key, \(nonce))
 
 # \(String(localized: "将加密后的数据转换为Base64编码"))
 encrypted_base64 = base64.b64encode(encrypted_data).decode()
 
 print("\(String(localized: "加密后的数据（Base64编码"))", encrypted_base64)
 
 deviceKey = '\(servers[0].key)'
 
 res = requests.get(f"\(servers[0].url)/{deviceKey}/test", params = {"ciphertext": encrypted_base64})
 
 print(res.text)
 """
    }
    
    
}

#Preview {
    CryptoConfigView()
        .environmentObject(PushbackManager.shared)
}

