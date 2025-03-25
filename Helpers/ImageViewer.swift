//
//  ImageViewer.swift
//  ImageSliderView
//
//  Created by Balaji Venkatesh on 20/12/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct ImageViewer<Content: View, Overlay: View>: View {
    /// Config
    var config = ImageViewerConfig()
    @ViewBuilder var content: Content
    @ViewBuilder var overlay: Overlay
    /// Giving updates to the main view
    var updates: (Bool, AnyHashable?) -> () = { _, _ in }
    /// View Properties
    @State private var isPresented: Bool = false
    @State private var activeTabID: Subview.ID?
    @State private var transitionSource: Int = 0
    @Namespace private var animation
    var body: some View {
        Group(subviews: content) { collection in
            /// Going to use new iOS 18 API to retrieve the Subview collection from the given view content
            LazyVGrid(columns: Array(repeating: GridItem(spacing: config.spacing), count: collection.count > 3 ? 2 : collection.count), spacing: config.spacing) {
                /// Only displaying the first four images, and the remaining ones showing a count (like +4) at the fourth image, similar to the X (Twitter) app
                let remainingCount = max(collection.count - 4, 0)
                ForEach(collection.prefix(4)) { item in
                    let index = collection.index(item.id)
                    GeometryReader {
                        let size = $0.size
                        
                        item
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(.rect(cornerRadius: config.cornerRadius))
                        
                        if collection.prefix(4).last?.id == item.id, remainingCount > 0 {
                            RoundedRectangle(cornerRadius: config.cornerRadius)
                                .fill(.black.opacity(0.35))
                                .overlay {
                                    Text("+\(remainingCount)")
                                        .font(.largeTitle)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    .frame(height: config.height)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        /// For opening the selected image in the detail tab view
                        activeTabID = item.id
                        /// For opening navigation detail view
                        isPresented = true
                        /// For Zoom Transition
                        transitionSource = index
                    }
                    .matchedTransitionSource(id: index, in: animation) { config in
                        config
                            .clipShape(.rect(cornerRadius: self.config.cornerRadius))
                    }
                }
            }
            .navigationDestination(isPresented: $isPresented) {
                TabView(selection: $activeTabID) {
                    ForEach(collection) { item in
                        item
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page)
                .background {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea()
                }
                .overlay {
                    overlay
                }
                .navigationTransition(.zoom(sourceID: transitionSource, in: animation))
                /// Hiding Tool Bar
                .toolbarVisibility(.hidden, for: .navigationBar)
            }
            /// Updating transitionSource when tab item get's changed
            .onChange(of: activeTabID) { oldValue, newValue in
                /// Consider this example: when the tab view at detail view is at index 6 or 7 and when it dismisses, the zoom transition won’t have any effect because there’s no matchedTransitionSource for that index. Therefore, indexes greater than 3 will always have a transition ID of 3
                transitionSource = min(collection.index(newValue), 3)
                sendUpdate(collection, id: newValue)
            }
            .onChange(of: isPresented) { oldValue, newValue in
                sendUpdate(collection, id: activeTabID)
            }
        }
    }
    
    private func sendUpdate(_ collection: SubviewsCollection, id: Subview.ID?) {
        if let viewID = collection.first(where: { $0.id == id })?.containerValues.activeViewID {
            updates(isPresented, viewID)
        }
    }
}

struct ImageViewerConfig {
    var height: CGFloat = 150
    var cornerRadius: CGFloat = 15
    var spacing: CGFloat = 10
}

/// To retrieve the current active ID, we can utilize container values to pass the ID to the view and then extract it from the subview
@available(iOS 18.0, *)
extension ContainerValues {
    @Entry var activeViewID: AnyHashable?
}


@available(iOS 18.0, *)
extension SubviewsCollection {
    func index(_ id: SubviewsCollection.Element.ID?) -> Int {
        firstIndex(where: { $0.id == id }) ?? 0
    }
}
