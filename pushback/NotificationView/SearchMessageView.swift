
import SwiftUI
import RealmSwift

struct SearchMessageView:View {

	var searchText: String
	@ObservedResults(Message.self) var messages
	
	init(searchText: String, group:String? = nil) {
		self.searchText = searchText
		if let group = group{
			self._messages =  ObservedResults(Message.self, filter: NSPredicate(format: "userInfo CONTAINS[c] %@ AND group ==[c] %@", searchText, group), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		}else{
			self._messages =  ObservedResults(Message.self, filter: NSPredicate(format: "userInfo CONTAINS[c] %@", searchText), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		}
		
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
			
			ForEach(messages, id: \.id) { message in
				MessageView(message: message, searchText: searchText, showGroup: true)
			}
		}
	}

}




