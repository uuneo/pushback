//
//  ImageDetailView.swift
//  pushback
//
//  Created by He Cho on 2024/10/16.
//
import SwiftUI
import RealmSwift

struct ImageDetailView:View {
	var image: String
	@Binding var imageUrl:String?
	@State var draggImage:String? = nil
	@State private var name:String = ""
	@FocusState private var photoNamesShow
	@State private var showSheet:Bool = false
	@State private var showSlideView:Bool = true
	var body: some View {
		
		ZStack{
			
			ToolsSlideView(show: $showSlideView){
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
				.padding(.vertical, 10)
				.customField(icon: "pencil")
				
				Spacer()
				
			}
			.padding()
			.toolbar {
				
				
				ToolbarItemGroup(placement: .keyboard) {
					Button("清除") {
						name = ""
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
		.presentationDetents([.height(320)])
		.interactiveDismissDisabled()
	}
	
	
	func reanameImage(){
		Task.detached(priority: .high) {
			let success = await ImageManager.renameImage(oldName: image, newName: name)
			if success {
				await MainActor.run {
					self.showSheet = false
					changeRealmImageNameName()
					self.showSlideView.toggle()
					DispatchQueue.main.asyncAfter(deadline: .now() + 2){
						NotificationCenter.default.post(name: .imageUpdate, object: nil, userInfo: ["name": name])
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
			let datas = realm.objects(Message.self).where({$0.url == image || $0.icon == image})
			
			for data in datas{
				try realm.write {
					if data.url == image{
						data.url = name
					}else if data.icon == image{
						data.icon = name
					}
					
				}
			}
			
		}catch{
			debugPrint(error.localizedDescription)
		}
	}
	
	
}
