
import SwiftUI

struct SearchMessageView:View {

	@Binding var searchText: String
    var group:String?
    @Environment(\.colorScheme) var  colorScheme
    @State private var messages:[Message] = []
    @State private var allCount:Int = 0
    @State private var searchTask: Task<Void, Never>?
	
    var body: some View {
        List{
            ForEach(messages, id: \.id) { message in
                MessageCard(message: message, searchText: searchText, showGroup: true){
                    self.hideKeyboard()
                    withAnimation(.easeInOut){
                        AppManager.shared.selectMessage = message
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .onAppear{
                    if messages.last == message{
                        loadData( item: message)
                    }
                }
            }
            
            Spacer()
                .frame(height: 30)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
            
        }
        .listStyle(.grouped)
        .if(colorScheme == .light) { view in
            view
                .background(.ultraThinMaterial)
        }
        .safeAreaInset(edge: .top, content: {
            HStack{
                Text("搜索结果")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                    
                Spacer()
                Text(verbatim: "\(messages.count) / \(max(allCount, messages.count))")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    
                
            }
            .padding(.horizontal)
            .padding(.bottom, 3)
            .background(.ultraThinMaterial)
        })
        .onChange(of: searchText) {  newValue in
            loadData()
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                loadData()
            }
        }
	}
    
    func loadData(limit:Int = 50, item:Message? = nil){
        
        searchTask?.cancel()
        
        self.searchTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 200_000_000) // 防抖延迟
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




