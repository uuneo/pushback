//
//  MessageDetailView.swift
//  Meow
//
//  Created by He Cho on 2024/8/10.
//





import SwiftUI
import RealmSwift

struct MessagesView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedResults(Message.self) var messages
	@Default(.images) var images
	@State private var searchText:String = ""
	var group:String?

	init(group: String? = nil) {
		if let group = group {
			self.group = group
			self._messages = ObservedResults(Message.self, where: { $0.group == group }, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
		}else{
			self._messages = ObservedResults(Message.self, sortDescriptor:  SortDescriptor(keyPath: \Message.createDate, ascending: false))
		}

	}

	@State private var imageDetail:ImageModel?

	// 分页相关状态
	@State private var currentPage: Int = 1
	@State private var itemsPerPage: Int = 50 // 每页加载10条数据
	@State private var isLoading: Bool = false

	var body: some View {

		List {

			if searchText.isEmpty{
				ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in

					MessageView(message: message, searchText: searchText){

						if let imageUrl = message.image.first{
							if let imageModel = images.first(where: { $0.url == imageUrl}){
								self.imageDetail = imageModel
							}else {
								Task{
									if let _ = await ImageManager.downloadImage(imageUrl),
									   let imageModel = images.first(where: { $0.url == imageUrl}){
										DispatchQueue.main.async{
											self.imageDetail = imageModel
										}

									}

								}
							}


						}else{
							debugPrint("没有找到")
						}
					}
					.onAppear{
						if messages.prefix(currentPage * itemsPerPage).last == message{
							self.currentPage = min(messages.count, self.currentPage + 1)
						}
					}
					.listRowBackground(Color.clear)
					.listSectionSeparator(.visible)


				}.onDelete(perform: $messages.remove)

			}else{
				SearchMessageView(searchText: searchText, group: group ?? "")
			}


		}
		.overlay {
			if let imageDetail {
				ImageDetailView(image: imageDetail,imageUrl: $imageDetail )
					.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
					.transition(.slide)
					.toolbar(.hidden, for: .navigationBar)
			}

		}
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
		.toolbar{
			ToolbarItem {
				Text("\(currentPage * itemsPerPage)/\(messages.count)")
					.font(.caption)
			}
		}
		.task {
			
			if let group = group{
				if let realm = try? Realm(), realm.objects(Message.self).where({$0.group == group && !$0.read}).count > 0 {
					RealmManager.shared.read( group)
				}
			}
		}


	}


}
