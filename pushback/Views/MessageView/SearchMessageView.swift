
import SwiftUI
import RealmSwift

struct SearchMessageView:View {

	var searchText: String
	@ObservedResults(Message.self) var messages
	
	init(searchText: String, group:String? = nil) {
		self.searchText = searchText
		if let group = group{
			self._messages =  ObservedResults(Message.self, filter: NSPredicate(format: "(body CONTAINS[c] %@ OR title CONTAINS[c] %@) AND group CONTAINS[c] %@", searchText, searchText, group), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		}else{
			self._messages =  ObservedResults(Message.self, filter: NSPredicate(format: "body CONTAINS[c] %@ OR title CONTAINS[c] %@ OR group CONTAINS[c] %@", searchText, searchText, searchText), sortDescriptor: SortDescriptor(keyPath: "createDate", ascending: false))
		}
		
	}
	
	var body: some View {
		LazyVStack{
			HStack{
				Text(String(format:String(localized: "找到%1$d条数据"), messages.count))
					.foregroundStyle(.gray)
					.padding(.leading)
				Spacer()
			}
			
			ForEach(messages, id: \.id) { message in
				MessageView(message: message, searchText: searchText)
			}
		}
	}

}




