//
//  CryptoConfigListView.swift
//  pushme
//
//  Created by lynn on 2025/8/3.
//

import SwiftUI
import Defaults

struct CryptoConfigListView: View {
    @Default(.cryptoConfigs) var cryptoConfigs
    @State private var showAddView:Bool = false
    @EnvironmentObject private var manager: AppManager
    
    
    var body: some View {
        List{
           
            Section{
                ForEach(cryptoConfigs,id: \.id){ item in
                    cryptoConfigCard( item: item, index: (cryptoConfigs.firstIndex(where: {$0.id == item.id}) ?? 0) + 1 )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                    
                        
                }
            }header:{
                Text("算法列表")
            }
        }
        .listStyle(.grouped)
        .navigationTitle( "算法配置")
        .toolbar {
            
            ToolbarItem(placement: .topBarTrailing) {
                Button{
                    let data = CryptoModelConfig.creteNewModel()
                    Defaults[.cryptoConfigs].append(data)
                    Haptic.impact()
                }label: {
                    Label("新增配置", systemImage: "plus.circle")
                }
            }
            
        }
    }
    
    
    
    
    @ViewBuilder
    func cryptoConfigCard(item: CryptoModelConfig, index: Int) -> some View{
        

            HStack(spacing: 20){
                VStack{
                    Text(String(format: "%02d", index))
                        .font(.title)
                        .fontWeight(.bold)
                }
                VStack(alignment: .leading, spacing: 5){
                    
                    HStack(spacing: 10){
                        Image(systemName: "bolt.shield")
                            .foregroundStyle(.blue)
                        Text(verbatim: "-")
                        Text(verbatim: item.algorithm.name)
                        Text(verbatim: "-")
                        Text(verbatim: item.mode.rawValue)
                        Spacer(minLength: 0)
                    }.lineLimit(1)
                    Divider()
                    HStack(spacing: 10){
                        Text("KEY:")
                            .foregroundStyle(.gray)
                            .padding(.trailing, 5)
                        Text(maskString(item.key))
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        Spacer(minLength: 0)
                    }
                    .lineLimit(1)
                }
                Spacer(minLength: 0)
                
                Menu{
                    
                    Section{
                        Button{
                            AppManager.shared.sheetPage = .crypto(item)
                        }label:{
                            Label("编辑", systemImage: "highlighter")
                        }.tint(.green)
                    }
                    
                    
                    if let config = item.obfuscator(){
                        Section{
                            Button{
                                let local = PBScheme.pb.scheme(host: .crypto, params: ["text" : config])
                                DispatchQueue.main.async{
                                    AppManager.shared.sheetPage = .quickResponseCode(text: local.absoluteString,title: String(localized: "配置文件"),preview: String(localized: "分享配置"))
                                }
                            }label:{
                                Label("分享", systemImage: "qrcode")
                            }
                            .tint(.orange)
                        }
                        
                    }
                    Section{
                        Button{
                            let data = cryptoExampleHandler(config: item)
                            Clipboard.set(data)
                            Toast.copy(title: "复制成功")
                        }label:{
                            Label("复制Pyhon示例", systemImage: "doc.on.doc")
                        }.tint(.green)
                    }
                   
                }label: {
                    Image(systemName: "menucard")
                        .imageScale(.large)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.message)
                    .shadow(group: false)
            )
            .swipeActions(edge: .leading, allowsFullSwipe: true){
                Button{
                    AppManager.shared.sheetPage = .crypto(item)
                }label:{
                    Label("编辑", systemImage: "highlighter")
                }.tint(.green)
            }
            .swipeActions{
                Button(role: .destructive){
                    if self.cryptoConfigs.count == 1{
                        self.cryptoConfigs = []
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            self.cryptoConfigs = [ CryptoModelConfig.data]
                        }
                    }else{
                        self.cryptoConfigs.removeAll(where: {$0.id == item.id})
                    }
                    
                }label:{
                    Label("删除", systemImage: "trash")
                }.tint(.red)
            }
        
        .frame(maxWidth: .infinity)
        
    }
    
    func cryptoExampleHandler(config: CryptoModelConfig) -> String {
    
        let servers = Defaults[.servers]
        
        let cipher = "AES.new(key, AES.MODE_\(config.mode.rawValue)\(config.mode == .ECB ?  "" : ", iv" ))"
        
        let paddedData = config.mode == .GCM ? "data.encode()" : "pad(data.encode(), AES.block_size)"
        
        let encryptedData = config.mode == .GCM ? "encrypted_data, tag = cipher.encrypt_and_digest(padded_data)" : "encrypted_data = cipher.encrypt(padded_data)"
        
        let encryptedDataReturn = config.mode == .GCM ? "iv + encrypted_data + tag" : "encrypted_data"
        
        let nonce = config.mode == .GCM ? "iv[:12]" : "iv"
        
        return """
 # Documentation: \(BaseConfig.docServer)\(String(localized: "/#/encryption"))
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
    
    fileprivate func maskString(_ str: String) -> String {
        guard str.count > 9 else { return String(repeating: "*", count: 3) +  str }
        return str.prefix(3) + String(repeating: "*", count: 3) + str.suffix(5)
    }
}

