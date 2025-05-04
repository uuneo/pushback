//
//  File name:     PaywallView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/23.


import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store:AppState
    @State private var selectProduct:Product?
    @State private var buyStatus:Bool = false
    @State private var openUrl:String?
    
    var body: some View {
        NavigationStack{
            VStack{
                
                
                HStack{
                    Text("获取开发者持续支持")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .padding(.leading, 25)
                    Spacer()
                }
                .padding(.bottom)
                
                Spacer(minLength: 0)
                
                
                HStack{
                    Spacer(minLength: 0)
                    ForEach(store.products, id: \.id) { product in
                        
                        VStack {
                            
                            Text(verbatim: product.displayPrice)
                                .font(.title.bold())
                                .foregroundStyle(.primary)
                            Text(verbatim: product.displayName)
                                .font(.headline)
                                .foregroundStyle(.gray)
                            
                        }
                        
                        .onAppear{
                            if product == store.products.first{
                                self.selectProduct = store.products.first
                            }
                        }
                        .frame(height: 130, alignment: .center)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .overlay {
                            if selectProduct == product{
                                ColoredBorder(lineWidth: 3, cornerRadius: 20)
                            }
                        }
                        .padding(10)
                        
                        .pressEvents(onRelease:{_ in
                            Task {
                                self.selectProduct = product
                            }
                            return true
                            
                        })
                        Spacer(minLength: 0)
                    }
                    
                }
                .frame(height: 150)
                
                Spacer(minLength: 0)
                
                HStack{
                    
                    Button{
                        Task{
                            self.buyStatus = true
                            if let selectProduct{
                                try await  store.purchase(selectProduct)
                                self.dismiss()
                            }
                            
                            self.buyStatus = false
                            
                        }
                    }label:{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.tint)
                            .frame(width: UIScreen.main.bounds.width - 20, height: 50, alignment: .center)
                            .overlay {
                                if buyStatus{
                                    HStack{
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    }
                                }else{
                                    Text("开启计划")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .disabled(buyStatus)
                    
                    
                }
                
                .padding(.vertical)
                
                
                HStack(spacing: 20){
                    Spacer()
                    Button{
                        self.openUrl = BaseConfig.privacyURL
                    }label: {
                        Text("隐私政策")
                    }
                    Button{
                        self.openUrl = BaseConfig.userAgreement
                    }label: {
                        Text("用户协议")
                    }
                    Button{
                        Task{
                            await store.restorePurchases()
                        }
                    }label: {
                        Text("恢复购买")
                    }
                    
                    Spacer()
                }
                .padding(.bottom)
                .font(.caption)
                .fullScreenCover(isPresented: Binding(get: {
                    openUrl != nil
                }, set: { value in
                    openUrl = nil
                })) {
                    if let openUrl{
                        SFSafariView(url: openUrl)
                            .ignoresSafeArea()
                    }
                    
                }
                
                
            }
            .navigationTitle("来杯咖啡，支持一下!")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        self.dismiss()
                    }, label: {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    })
                }
            }
            
        }.presentationDetents([ISPAD ? .height(500) : .medium])
    }
}

#Preview {
    NavigationStack{
        SettingsPage()
            .environmentObject(PushbackManager.shared)
            .environmentObject(AppState.shared)
    }
}
