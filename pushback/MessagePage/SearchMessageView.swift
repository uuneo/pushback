
import SwiftUI
import RealmSwift

struct SearchMessageView:View {

	var searchText: String
	@ObservedResults(Message.self) var messages

	// 分页相关状态
	@State private var currentPage: Int = 1
	@State private var itemsPerPage: Int = 10 // 每页加载10条数据

	init(searchText: String, group: String? = nil) {
		self.searchText = searchText
		if let group = group, !group.isEmpty {
			self._messages = ObservedResults(Message.self, filter: NSPredicate(format: "userInfo CONTAINS[c] %@ AND group ==[c] %@", searchText, group), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		} else {
			self._messages = ObservedResults(Message.self, filter: NSPredicate(format: "userInfo CONTAINS[c] %@", searchText), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		}
		self.currentPage = 1
	}
	
	var body: some View {
		Group{
			HStack{
				Spacer()
				Text(String(format: String(localized: "找到%1$d条数据"), messages.count))
					.foregroundStyle(.gray)
					.padding(.trailing, 10)
				
			}
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)
			
			ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in
                MessageCard(message: message, searchText: searchText, showGroup: true)
					.onAppear{
						if messages.prefix(currentPage * itemsPerPage).last == message{
							self.currentPage = min(messages.count, self.currentPage + 1)
						}
					}
			}
		}
	}

}




