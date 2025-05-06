//
//  Home.swift
//
//
//  Created by uuneo on 2025/2/22.
//

import SwiftUI


/// Page Intro Model
struct PageIntro: Identifiable, Hashable {
    var id: UUID = .init()
    var introAssetImage: String
    var title: String
    var subTitle: String
    var displaysAction: Bool = false
}

var pageIntros: [PageIntro] = [
    .init(introAssetImage: "Page 1", title: String(localized: "允许必要的权限"), subTitle: String(localized: "网络权限用来获取苹果提送密钥和通知权限用来接收通知.")),
    .init(introAssetImage: "Page 2", title: String(localized: "文字、图片、视频\n轻松推送到手机"), subTitle: String(localized: "任意浏览器，脚本语言都可以把内容发送到您的手机上,会上网就会使用.")),
    .init(introAssetImage: "Page 3", title: String(localized: "不需要任何的设置\n 打开即用"), subTitle: String(localized: "每个月需要打开一次App用来更新设备推送密钥."), displaysAction: true)
]

struct CustomIndicatorView: View {
    /// View Properties
    var totalPages: Int
    var currentPage: Int
    var activeTint: Color = .black
    var inActiveTint: Color = .gray.opacity(0.5)
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) {
                Circle()
                    .fill(currentPage == $0 ? activeTint : inActiveTint)
                    .frame(width: 4, height: 4)
            }
        }
    }
}


struct LauchFirstStartView: View {
    /// View Properties
    @State private var activeIntro: PageIntro = pageIntros[0]
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var keyboardHeight: CGFloat = 0
	@State private var show:Bool = true
	var complete:(() -> Void)? = nil
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            IntroView(intro: $activeIntro, size: size) {
                /// User Login/Signup View
                VStack(spacing: 10) {
                    
                    Spacer(minLength: 10)
                    
                    Button {
						
                        withAnimation {
                            self.show.toggle()
                            complete?()
                        }
                    } label: {
                        Text("开始使用")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background {
                                Capsule()
                                    .fill(.black)
                            }
                    }
                }
                .padding(.top, 25)
            }
			.opacity(show ? 1 : 0.1)
        }
        .padding(15)
        .offset(y: -keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .all)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { output in
            if let info = output.userInfo, let height = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
                keyboardHeight = height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: keyboardHeight)
    }
}


/// Intro View
struct IntroView<ActionView: View>: View {
    @Binding var intro: PageIntro
    var size: CGSize
    var actionView: ActionView
    
    init(intro: Binding<PageIntro>, size: CGSize, @ViewBuilder actionView: @escaping () -> ActionView) {
        self._intro = intro
        self.size = size
        self.actionView = actionView()
    }
    
    /// Animation Properties
    @State private var showView: Bool = false
    @State private var hideWholeView: Bool = false
    var body: some View {
        VStack {
            /// Image View
            GeometryReader {
                let size = $0.size
                
                Image(intro.introAssetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(15)
					.padding(.top, 50)
                    .frame(width: size.width, height: size.height)
            }
            /// Moving Up
            .offset(y: showView ? 0 : -size.height / 2)
            .opacity(showView ? 1 : 0)
            
            /// Tile & Action's
            VStack(alignment: .leading, spacing: 10) {
                Spacer(minLength: 0)
                
                Text(intro.title)
                    .font(.title)
					.fontWeight(.bold)
					.foregroundStyle(.blue)
                
                Text(intro.subTitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 15)
                
                if !intro.displaysAction {
                    Group {
                        Spacer(minLength: 25)
                        
                        /// Custom Indicator View
                        CustomIndicatorView(totalPages: filteredPages.count, currentPage: filteredPages.firstIndex(of: intro) ?? 0)
                            .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 10)
                        
                        Button {
                            changeIntro()
                        } label: {
							Text( "继续")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: size.width * 0.4)
                                .padding(.vertical, 15)
                                .background {
                                    Capsule()
                                        .fill(.black)
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    /// Action View
                    actionView
                        .offset(y: showView ? 0 : size.height / 2)
                        .opacity(showView ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            /// Moving Down
            .offset(y: showView ? 0 : size.height / 2)
            .opacity(showView ? 1 : 0)
        }
        .offset(y: hideWholeView ? size.height / 2 : 0)
        .opacity(hideWholeView ? 0 : 1)
        /// Back Button
        .overlay(alignment: .topLeading) {
            /// Hiding it for Very First Page, Since there is no previous page present
            if intro != pageIntros.first {
                Button {
                    changeIntro(true)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
						.foregroundColor(.primary)
                        .contentShape(Rectangle())
                }
                .padding(10)
                /// Animating Back Button
                /// Comes From Top When Active
                .offset(y: showView ? 0 : -200)
                /// Hides by Going back to Top When In Active
                .offset(y: hideWholeView ? -200 : 0)
            }
        }
		
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                showView = true
            }
        }
    }
    
    /// Updating Page Intro's
    func changeIntro(_ isPrevious: Bool = false) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
            hideWholeView = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            /// Updating Page
            if let index = pageIntros.firstIndex(of: intro), (isPrevious ? index != 0 : index != pageIntros.count - 1) {
                intro = isPrevious ? pageIntros[index - 1] : pageIntros[index + 1]
            } else {
                intro = isPrevious ? pageIntros[0] : pageIntros[pageIntros.count - 1]
            }
            /// Re-Animating as Split Page
            hideWholeView = false
            showView = false
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                showView = true
            }
        }
    }
    
    var filteredPages: [PageIntro] {
        return pageIntros.filter { !$0.displaysAction }
    }
}
