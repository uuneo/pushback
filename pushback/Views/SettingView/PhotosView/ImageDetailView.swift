//
//  ImageDetailView.swift
//  pushback
//
//  Created by He Cho on 2024/10/16.
//
import SwiftUI

struct ImageDetailView:View {
	var image: String
	@Binding var imageUrl:String?
	@State var draggImage:String? = nil
	@State private var name:String = ""
	@FocusState private var photoNamesShow
	@State private var showSheet:Bool = false
	var body: some View {
		
		ZStack{
			
			ToolsSlideView{
				uAsyncImage(url: image, size: CGSize(width: UIScreen.main.bounds.width  - 20, height: UIScreen.main.bounds.height * 0.8), mode: .fit, isThumbnail: false)
					.navigationBarHidden(true)
					.onAppear{
						self.name = image
					}
					
					
			}dismiss: {
				self.imageUrl = nil
			}leftButton: {
				self.showSheet.toggle()
			}
			
			
			
		}
		.sheet(isPresented: $showSheet){
			changeImageKey()
		}
		.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		.background(.ultraThinMaterial)
		.ignoresSafeArea()
	}
	
	
	@ViewBuilder
	func changeImageKey() -> some View{
		NavigationStack{
			VStack(alignment: .leading){
				
				Text("本地化地址")
					.font(.largeTitle)
					.fontWeight(.heavy)
					.padding(.top, 5)
				
				Text(String(format: String(localized: "远程本地化地址: %1$@"), name))
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(.gray)
					.padding(.top, -5)
				
				TextField(text: $name) {
					Label("修改", systemImage: "pencil")
				}
				.focused($photoNamesShow)
				.padding(.vertical)
				.customField(icon: "pencil")
				Spacer()
				
			}
			.padding()
			.toolbar {
				
				ToolbarItem(placement: .keyboard) {
					customKeyboardTools(show: $photoNamesShow,clear: {
						self.name = ""
					})
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button{
						Task.detached(priority: .high) {
							let success = await ImageManager.renameImage(oldName: image, newName: name)
							if success {
								await MainActor.run {
									self.showSheet.toggle()
								}
								try? await Task.sleep(for: .seconds(0.6))
								
								await MainActor.run {
									self.imageUrl = nil
									self.name = ""
								}
							}
							
						}
					}label: {
						Text("完成")
					}
				}
				
				
				
				ToolbarItem(placement: .topBarLeading) {
					Button(action: {
						self.showSheet.toggle()
					}, label: {
						Image(systemName: "arrow.left")
							.font(.title2)
							.foregroundStyle(.gray)
					})
				}
				
			}
			
		}
		.presentationDetents([.height(320)])
		.interactiveDismissDisabled()
	}
}
