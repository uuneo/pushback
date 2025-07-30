//
//  CustomTabBar.swift
//  TabBariOS26
//
//  Created by Balaji Venkatesh on 12/07/25.
//

import SwiftUI
import Defaults

struct CustomTabBar: View {
    var size: CGSize
    var activeTab: TabPage
    @Binding var searchText: String
    var onSearchBarExpanded: (Bool) -> ()
    var onSearchTextFieldActive: (Bool) -> ()
    var changeTabBar: (TabPage, Int)-> ()
    /// View Properties
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    //    @State private var dragOffset: CGFloat = 0
    //    @State private var lastDragOffset: CGFloat?
    /// Search Bar Properties
    @Default(.showGroup) var showGroup
    @State private var isSearchExpanded: Bool = false
    @FocusState private var isKeyboardActive: Bool
    
    var showsSearchBar: Bool{ activeTab.showSearch }
    
    var tabs:[TabPage]{
        Array(TabPage.allCases.prefix(showsSearchBar ? 4 : 5))
    }
    var tabItemWidth: CGFloat {
        max(min(size.width / CGFloat(tabs.count + (showsSearchBar ? 1 : 0)), 90), 60)
    }
    let tabItemHeight: CGFloat = 56
    
    var dragOffset: CGFloat {
        CGFloat(activeTab.index) * tabItemWidth
    }
    
    var body: some View {
        
        ZStack {
            
            let mainLayout = isKeyboardActive ? AnyLayout(ZStackLayout(alignment: .leading)) : AnyLayout(HStackLayout(spacing: 12))
            
            mainLayout {
                let tabLayout = isSearchExpanded ? AnyLayout(ZStackLayout()) : AnyLayout(HStackLayout(spacing: 0))
                
                tabLayout {
                    ForEach(tabs, id: \.rawValue) { tab in
                        TabItemView(
                            tab,
                            width: isSearchExpanded ? 45 : tabItemWidth,
                            height: isSearchExpanded ? 45 : tabItemHeight
                        )
                        .opacity(isSearchExpanded ? (activeTab == tab ? 1 : 0) : 1)
                    }
                }
                /// Draggable Active Tab
                .background(alignment: .leading) {
                    ZStack {
                        Capsule(style: .continuous)
                            .stroke(.gray.opacity(0.25), lineWidth: 3)
                            .opacity(isActive ? 1 : 0)
                        
                        Capsule(style: .continuous)
                            .fill(.background)
                    }
                    .compositingGroup()
                    .frame(width: tabItemWidth, height: tabItemHeight)
                    /// Scaling when drag gesture becomes active
                    .scaleEffect(isActive ? 1.3 : 1)
                    .offset(x: isSearchExpanded ? 0 : dragOffset)
                    .opacity(isSearchExpanded ? 0 : 1)
                }
                .padding(3)
                .background(TabBarBackground())
                .overlay {
                    if isSearchExpanded {
                        Capsule()
                            .foregroundStyle(.clear)
                            .contentShape(.capsule)
                            .onTapGesture {
                                withAnimation(.bouncy) {
                                    isSearchExpanded = false
                                }
                                Haptic.impact()

                            }
                    }
                }
                /// Hiding when keyboard is active
                .opacity(isKeyboardActive ? 0 : 1)
                
                if showsSearchBar {
                    ExpandableSearchBar(height: isSearchExpanded ? 45 : tabItemHeight)
                }
            }
            .optionalGeometryGroup()
            
        }
        /// Centering Tab Bar
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .frame(height: 56)
        .padding(.bottom, isKeyboardActive ? 10 : 0)
        /// Animations (Customize it as per your needs!)
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
        .animation(.easeInOut(duration: 0.25), value: isKeyboardActive)
        .customOnChange(value: isKeyboardActive) { status in
            withAnimation{
                onSearchTextFieldActive(status)
            }
            
        }
        .customOnChange(value: isSearchExpanded) { status in
            withAnimation{
                onSearchBarExpanded(status)
            }
        }
    }
    
    /// Tab Item View
    @ViewBuilder
    private func TabItemView(_ tab: TabPage, width: CGFloat, height: CGFloat) -> some View {
        if tab == .message && activeTab == .message {
            Menu {
                Section{
                    Button{
                        changeTabBar(tab, 1)
                        Haptic.impact()
                    }label:{
                        
                        Label(showGroup ? "列表模式" : "分组模式", systemImage: showGroup ? "rectangle.3.group.bubble.left" : "checklist")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                            .animation(.easeInOut, value: showGroup)
                            .symbolEffect(delay: 0)
                    }
                }
                
                Section{
                    Button{
                        changeTabBar(tab, 0)
                        Haptic.impact()
                    }label: {
                        Label("使用示例", systemImage: "questionmark.bubble")
                            .symbolRenderingMode(.palette)
                            .customForegroundStyle(.accent, .primary)
                            .symbolEffect(delay: 0)
                    }
                }
                
                                
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: tab.symbol)
                        .font(.title2)
                        .symbolVariant(activeTab == tab  ? .fill : .none)
                        .symbolRenderingMode(.palette)
                        .symbolEffect(activeTab == tab  ? tab.animate : .none)
                        .customForegroundStyle(activeTab == tab && !isSearchExpanded ? .white : Color.gray, activeTab == tab && !isSearchExpanded ? .accent : Color.gray)
                        .scaleEffect(tab == .setting ? 1.2 : 1)
                    
                    if !isSearchExpanded {
                        Text(tab.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .customForegroundStyle(activeTab == tab && !isSearchExpanded ? accentColor : Color.gray, Color.primary)
                    }
                }
                .frame(width: width, height: height)
                .contentShape(.capsule)
                .optionalGeometryGroup()
            }
        }else{
          
            
            VStack(spacing: 6) {
                Image(systemName: tab.symbol)
                    .font(.title2)
                    .symbolVariant(activeTab == tab  ? .fill : .none)
                    .symbolRenderingMode(.palette)
                    .symbolEffect(activeTab == tab  ? tab.animate : .none)
                    .customForegroundStyle(activeTab == tab && !isSearchExpanded ? .white : Color.gray, activeTab == tab && !isSearchExpanded ? .accent : Color.gray)
                    .scaleEffect(tab == .setting ? 1.2 : 1)
                
                if !isSearchExpanded {
                    Text(tab.title)
                        .font(.caption2)
                        .lineLimit(1)
                        .customForegroundStyle(activeTab == tab && !isSearchExpanded ? accentColor : Color.gray, Color.primary)
                }
            }
            .frame(width: width, height: height)
            .contentShape(.capsule)
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        changeTabBar(tab, -1)
                    }
            )
            .optionalGeometryGroup()

        }
        
        
    }
    
    /// Tab Bar Background View
    @ViewBuilder
    private func TabBarBackground() -> some View {
        ZStack {
            Capsule(style: .continuous)
                .stroke(.gray.opacity(0.25), lineWidth: 1.5)
            
            Capsule(style: .continuous)
                .fill(.background.opacity(0.8))
            
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .compositingGroup()
    }
    
    /// Expandable Search Bar
    @ViewBuilder
    private func ExpandableSearchBar(height: CGFloat) -> some View {
        let searchLayout = isKeyboardActive ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(ZStackLayout(alignment: .trailing))
        
        searchLayout {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(isSearchExpanded ? .body : .title2)
                    .foregroundStyle(isSearchExpanded ? .gray : Color.primary)
                    .frame(width: isSearchExpanded ? nil : height, height: height)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            isSearchExpanded = true
                        }
                        Haptic.impact()
                    }
                    .allowsHitTesting(!isSearchExpanded)
                
                if isSearchExpanded {
                    TextField("Search...", text: $searchText)
                        .focused($isKeyboardActive)
                }
            }
            .padding(.horizontal, isSearchExpanded ? 15 : 0)
            .background(TabBarBackground())
            .optionalGeometryGroup()
            .zIndex(1)
            
            /// Close Button
            Button {
                searchText = ""
                isKeyboardActive = false
                Haptic.impact()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(Color.primary)
                    .frame(width: height, height: height)
                    .background(TabBarBackground())
            }
            /// Only Showing when keyboard is active
            .opacity(isKeyboardActive ? 1 : 0)
        }
    }
    
    var accentColor: Color {
        return .blue
    }
}

#Preview {
    ContentView()
}

extension View {
    @ViewBuilder
    func optionalGeometryGroup() -> some View {
        if #available(iOS 17, *) {
            self
                .geometryGroup()
        } else {
            self
        }
    }
}
