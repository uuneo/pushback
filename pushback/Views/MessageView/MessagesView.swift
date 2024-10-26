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
	@State private var searchText:String = ""
	var group:String?
	
	init(group: String? = nil) {
		self.group = group
		self._messages = ObservedResults(Message.self, where: { $0.group == (group ?? "") }, sortDescriptor:  SortDescriptor(keyPath: "createDate", ascending: false))
	}
	
	var body: some View {
		
		List {
			if let messages = loadMessage(){
				ForEach(messages, id: \.id) { message in
					
					MessageView(message: message, searchText: searchText)
						.swipeActions(edge: .leading) {
							Button {
								RealmProxy.shared.read(message)
								Toast.shared.present(title: String(localized:  "信息状态已更改"), symbol: "highlighter")
							} label: {
								Label(message.read ? String(localized: "已读") :  String(localized: "未读"), systemImage: message.read ? "envelope.open": "envelope")
							}.tint(.blue)
						}
					
						.listRowBackground(Color.clear)
						.listSectionSeparator(.hidden)
					
					
				}
				.onDelete { indexSet in
					for index in indexSet{
						RealmProxy.shared.delete( messages[index])
					}
				}
			}
			
			
			
			
		}
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic)){
			SearchMessageView(searchText: searchText, group: group ?? "")
		}
		.toolbar{
			ToolbarItem {
				Text("\(messages.count)")
					.font(.caption)
			}
		}
	
		.onAppear{
			if let group = group{
				RealmProxy.shared.read( group)
			}
			
		}
		
	}
	
	func loadMessage() -> [Message]?{
		
		messages.filter({
			searchText.isEmpty || ($0.title?.contains(searchText) ?? false) || ($0.body?.contains(searchText) ?? false)
		})
	}
	
}
