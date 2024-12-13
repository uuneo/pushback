//
//  ImageDetailView.swift
//  pushback
//
//  Created by He Cho on 2024/10/16.
//
import SwiftUI
import RealmSwift

struct ImageDetailView:View {
	var image: ImageCacheModel
	@Binding var imageUrl:ImageCacheModel?
	@State var draggImage:String? = nil
	@State private var localName:String = ""
	@FocusState private var photoNamesShow
	@State private var showSheet:Bool = false
	@State private var showSlideView:Bool = true
	var body: some View {
		
		ZStack{
			
			ToolsSlideView(show: $showSlideView){
				
				uAsyncImage(imageCache: image, size: CGSize(width: UIScreen.main.bounds.width  - 20, height: UIScreen.main.bounds.height * 0.8), mode: .fit, isThumbnail: false)
					.navigationBarHidden(true)
					
					
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
				
				Text("远程本地化")
					.font(.largeTitle)
					.fontWeight(.heavy)
					.padding(.top, 5)
					.onAppear{
						
						self.localName = image.local ?? ""
					}
				
				Divider()
				
				Text("原始地址:")
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(.gray)
					.padding(.top, -5)
				
				Text(image.url)
					.lineLimit(1)
					.font(.title3)
					.customField(icon: "doc.on.doc"){
						PushbackManager.shared.copy(image.url)
						Toast.shared.present(title: String(localized: "复制成功"), symbol: "doc.on.doc")
					}
				
				Divider()
				Text("输入一个字符串 远程可以直接使用：")
					.font(.caption)
					.fontWeight(.semibold)
					.foregroundStyle(.gray)
					.padding(.top, -5)
				
				TextField(text:  Binding(
					get: {
						localName
					},
					set: {
						// 确保更新后无 "+" 和空格
						localName = $0.replacingOccurrences(of: "+", with: "")
							.replacingOccurrences(of: " ", with: "")
					}
				)) {
					Label("输入本地地址", systemImage: "pencil")
				}
				.focused($photoNamesShow)
				.padding(.vertical, 10)
				.customField(icon: "pencil"){
					self.photoNamesShow.toggle()
				}
				
				
				Spacer()
				
			}
			.padding()
			.toolbar {
				
				
				ToolbarItemGroup(placement: .keyboard) {
					Button("清除") {
						localName = ""
					}
					Spacer()
					Button("完成") {
						PushbackManager.shared.hideKeyboard()
					}
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button{
						reanameImage()
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
		.presentationDetents([.height(360)])
		.interactiveDismissDisabled()
		
	}
	
	
	func reanameImage(){
		Task.detached(priority: .high) {
			let success = await ImageManager.renameImage(item: image, newName: localName)
			if success {
				await MainActor.run {
					self.showSheet = false
					changeRealmImageNameName()
					self.showSlideView.toggle()
					DispatchQueue.main.asyncAfter(deadline: .now() + 2){
						NotificationCenter.default.post(name: .imageUpdate, object: nil, userInfo: ["name": localName])
					}
				}
			}else{
				Toast.shared.present(title: String(localized: "文件重复"), symbol: .info)
			}
			
		}
	}
	
	func changeRealmImageNameName(){
		do{
			let realm = try Realm()
			let datas = realm.objects(Message.self).where({$0.url == image.name || $0.icon == image.name})
			
			for data in datas{
				try realm.write {
					if data.url == image.name{
						data.url = localName
					}else if data.icon == image.name{
						data.icon = localName
					}
					
				}
			}
			
		}catch{
			debugPrint(error.localizedDescription)
		}
	}
	
	
}
