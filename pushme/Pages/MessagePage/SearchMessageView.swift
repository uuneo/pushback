
import SwiftUI

struct SearchMessageView:View {

	@Binding var searchText: String
    var group:String?
    
    @State private var messages:[Message] = []
    @State private var allCount:Int = 0
    @State private var searchTask: Task<Void, Never>?
	
	var body: some View {
        List{
            
            ForEach(messages, id: \.id) { message in
                MessageCard(message: message, searchText: searchText, showGroup: true){
                    withAnimation(.easeInOut) {
                        AppManager.hideKeyboard()
                        DispatchQueue.main.async {
                            AppManager.shared.selectMessage = message
                        }
                    }
                }
                    .onAppear{
                        if messages.last == message{
                            loadData( item: message)
                        }
                    }
            }
            
        }
        .safeAreaInset(edge: .top, content: {
            HStack{
                Spacer()
                Text("\(messages.count) / \(max(allCount, messages.count))")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.trailing, 20)
                
            }
            .background(.ultraThinMaterial)
        })
        .onChange(of: searchText) {  newValue in
            loadData()
        }
	}
    
    func loadData(limit:Int = 50, item:Message? = nil){
        
        searchTask?.cancel()
        
        self.searchTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 300_000_000) // 防抖延迟
            guard !Task.isCancelled else { return }
            
            let results = await DatabaseManager.shared.query(search: searchText, group: group, limit: limit, item?.createDate)
             DispatchQueue.main.async{
                if item == nil{
                    self.messages = results.0
                }else{
                    self.messages += results.0
                }
                self.allCount = results.1
            }
        }
    }
    
}




