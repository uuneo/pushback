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
    
    @Environment(\.editMode) private  var editMode
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
    
    
    @State private var showTextAnimation:Bool = false
    
    @State private var sharkText:String = ""
    @FocusState private var sharkfocused:Bool
    @State private var success:Bool = false
    
    
    init(config: String?){
        if let text = config{
            self._sharkText = State(wrappedValue: text)
            if let config = CryptoModelConfig.deobfuscator(result: sharkText){
                Defaults[.cryptoConfig] = config
                self._success = State(wrappedValue: true)
            }
        }
    }
    
    var body: some View {
        
        List {
            
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
                        if !value, let config = CryptoModelConfig.deobfuscator(result: sharkText){
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
                    .textCase(.none)
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
                        Text("Iv：")
                    } icon: {
                        Image(systemName: "dice")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.tint, Color.primary)
                        
                    }
                    Spacer()
                    TextField("请输入16位Iv",text: $cryptoConfig.iv)
                        .focused($ivFocus)
                        .onDisappear{
                            let _ = verifyIv()
                        }
                        .foregroundStyle(.gray)
                        .if(editMode?.wrappedValue != .active){ view in
                            HackerTextView(text: cryptoConfig.iv, trigger:showTextAnimation)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1) // 确保文本在一行内
                        }
                    
                }
                
                HStack{
                    Label {
                        Text("Key:")
                    } icon: {
                        Image(systemName: "key")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle( Color.primary, .tint)
                    }
                    Spacer()
                    
                    
                    TextField(String(format: String(localized: "输入%d位数的key"), expectKeyLength),text: $cryptoConfig.key)
                        .focused($keyFocus)
                        .onDisappear{
                            let _ = verifyKey()
                        }
                        .foregroundStyle(.gray)
                        .if(editMode?.wrappedValue != .active){ view in
                            
                            HackerTextView(text: cryptoConfig.key, trigger:showTextAnimation)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1) // 确保文本在一行内
                            
                        }
                    
                }
                
                
               
                
            }header:{
                Button {
                    cryptoConfig.iv = CryptoModelConfig.generateRandomString()
                    cryptoConfig.key = CryptoModelConfig.generateRandomString(cryptoConfig.algorithm.rawValue)
                    self.showTextAnimation.toggle()
                } label: {
                    Label("随机生成密钥", systemImage: "dice")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.green, Color.primary)
                        .textCase(.none)
                    
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
                    AppManager.hideKeyboard()
                }
            }
            
            
            if let config = cryptoConfig.obfuscator(){
                ToolbarItem {
                    Button{
                        let local = PBScheme.pb.scheme(host: .crypto, params: ["text" : config])
                        AppManager.shared.sheetPage = .quickResponseCode(text: local.absoluteString,title: String(localized: "配置文件"),preview: String(localized: "分享配置"))
                    }label:{
                        Label("分享", systemImage: "qrcode")
                    }
                }
            }
            
            
            ToolbarItem{
                EditButton()
            }
            
        }
        
    }
    func verifyKey(_ showMsg:Bool = true)-> Bool{
        if cryptoConfig.key.count != expectKeyLength{
            cryptoConfig.key = ""
            if showMsg{
                Toast.info(title: "自动更正Key参数")
            }
            return false
        }
        return true
    }
    
    func verifyIv(_ showMsg:Bool = true) -> Bool{
        if cryptoConfig.iv.count != 16 {
            cryptoConfig.iv = ""
            if showMsg{
                Toast.info(title: "自动更正Iv参数")
            }
            return false
        }
        return true
    }
    
    
    func verifyCopyText(_ showMsg:Bool = true){
        
        
        if !verifyIv(showMsg) {
            cryptoConfig.iv = CryptoModelConfig.generateRandomString()
        }
        
        if !verifyKey(showMsg){
            cryptoConfig.key = CryptoModelConfig.generateRandomString(cryptoConfig.algorithm.rawValue)
        }
        
        
        if !showMsg{
            Clipboard.set( cryptoExampleHandler() )
            Toast.copy(title:  "复制成功")
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
 # Documentation: \(String(localized: "https://pushback.uuneo.com/#/encryption"))
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
    CryptoConfigView(config: nil)
        .environmentObject(AppManager.shared)
}
