//
//  ServerCardView.swift
//  pushback
//
//  Created by uuneo 2024/10/30.
//

import SwiftUI
import Defaults




struct ServerCardView:View {
    @EnvironmentObject private var manager: AppManager
    @State private var textAnimation:Bool = false
    @State private var showDevice:Bool = false
	var item: PushServerModel
	var isCloud:Bool = false
    var complete:() -> Void
	
	var body: some View {
        VStack{
            
            if showDevice{
                HStack{
                    Image(systemName: "qrcode")
                        .imageScale(.small)
                        .foregroundStyle(.gray)
                    Text(item.device)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.accent)
                    Spacer()
                }
                .font(.caption2)
                .padding(5)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.leading, 10)
            }
            
            
            HStack(spacing: 10){
                
                Group{
                    if !isCloud {
                        Image(systemName:  "externaldrive.badge.wifi")
                            .scaleEffect(1.5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(item.status ? .green : .red, Color.primary)
                            .padding(.horizontal,5)
                            .if(!item.status, transform: { view in
                                view
                                    .symbolEffect(.variableColor, delay: 1)
                                
                            })
                    }else{
                        Image(systemName: "externaldrive.badge.icloud")
                            .scaleEffect(1.5)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.accent, Color.primary)
                            .padding(.horizontal,5)
                    }
                }
                
                .VButton( onRelease: { _ in
                    if !showDevice{
                        withAnimation(.easeInOut) {
                            self.showDevice = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                            withAnimation(.easeInOut) {
                                self.showDevice = false
                            }
                        }
                        return true
                    }
                    return false
                })
                
                VStack(alignment: .leading,spacing: 5){
                    
                    HStack(alignment: .center){
                        Text( String(localized: "服务器") + ":")
                            .font(.caption2)
                            .frame(width:40, alignment: .trailing)
                            .foregroundStyle(.gray)
                        
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    Divider()
                    HStack(alignment: .center){
                        Text("KEY:")
                            .font(.caption2)
                            .frame(width:40, alignment: .trailing)
                            .foregroundStyle(.gray)
                        Text(item.key)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    
                }
                .VButton(onRelease: { _ in
                    let local = PBScheme.pb.scheme(host: .server, params: ["text": item.server])
                    manager.sheetPage = .quickResponseCode(text: local.absoluteString, title: String(localized: "服务器配置"),preview: nil)
                    return true
                })
                
                Spacer()
                
                if isCloud{
                    Image(systemName: "icloud.and.arrow.down")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .symbolEffect(.bounce,delay: 1)
                        .onTapGesture {
                            complete()
                        }
                }else {
                    Image(systemName: "doc.on.doc")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle( .tint, Color.primary)
                        .symbolEffect(.bounce,delay: 1)
                        .onTapGesture {
                            complete()
                            self.textAnimation.toggle()
                        }
                }
                
                
            }
            
            
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.message)
                .shadow(group: true)
        )
        .padding(.vertical, 5)
        .transaction { view in
            view.animation = .snappy
        }
	}
}
