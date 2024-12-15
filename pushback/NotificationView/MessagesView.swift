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
			self._messages = ObservedResults(Message.self, where: { $0.group == group }, sortDescriptor:  SortDescriptor(keyPath: "createDate", ascending: false))
		}else{
			self._messages = ObservedResults(Message.self, sortDescriptor:  SortDescriptor(keyPath: "createDate", ascending: false))
		}

	}

	@State private var imageDetail:ImageCacheModel?

	var body: some View {

		List {

			if searchText.isEmpty{
				ForEach(messages, id: \.id) { message in

					MessageView(message: message, searchText: searchText){

						if let imageUrl = message.image.first, let imageModel = images.first(where: { $0.url == imageUrl}){
							self.imageDetail = imageModel
						}else{
							debugPrint("没有找到")
						}
					}
					.swipeActions(edge: .leading) {
						Button {
							RealmManager.shared.read(message)
							Toast.shared.present(title: String(localized:  "信息状态已更改"), symbol: "highlighter")
						} label: {
							Label(message.read ? "已读" :  "未读", systemImage: message.read ? "envelope.open": "envelope")
						}.tint(.blue)
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
			}

		}
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
		.toolbar{
			ToolbarItem {
				Text("\(messages.count)")
					.font(.caption)
			}
		}
		.onAppear{
			if let group = group{
				RealmManager.shared.read( group)
			}

		}

	}


}
