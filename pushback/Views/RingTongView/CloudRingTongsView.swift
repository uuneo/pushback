//
//  CloudRingTongsView.swift
//  pushback
//
//  Created by He Cho on 2024/11/11.
//

import SwiftUI
import CloudKit


struct CloudRingTongsView : View {
	@State private var searchText:String = ""
	@State private var topDatas: [RingtoneCloudData] = []
	@State private var datas: [RingtoneCloudData] = []
	@State private var isLoading: Bool = false
	@State private var cursor: CKQueryOperation.Cursor?
	@StateObject private var cloud = RingsTongCloudKit.shared
	@Environment(\.isSearching) var isSearching
	
	var body: some View {
		NavigationStack {
			List{
				if isLoading && datas.isEmpty && topDatas.isEmpty {
					HStack{
						Spacer()
						ProgressView("加载中...")
							.padding()
						Spacer()
					}
					.listRowBackground(Color.clear)
				} else {
					
					
					if isSearching {
						
						Section {
							ForEach(datas, id: \.id) { result in
								RingtoneItemView(audio: result.data, fileName: result.name, ringType: .cloud)
							}
						} header: {
							Text("搜索结果")
								.foregroundStyle(.gray)
						}

					}else{
						Section {
							ForEach(topDatas, id: \.id) { result in
								RingtoneItemView(audio: result.data, fileName: result.name, ringType: .cloud)
							}
						} header: {
							Text("下载量前30")
								.foregroundStyle(.gray)
						}

						
					}
					
					
					
				}
				
			}
			.onAppear {
				loadInitialData()
			}
			.navigationTitle("云端共享")
			
			
		}
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic),  prompt: Text("搜索云端共享铃声"))
		
	}
	
	
	// 初次加载数据
	private func loadInitialData() {
		
		isLoading = true
		if searchText.isEmpty {
			// 加载Top数据
			cloud.fetchTop30ByCount { result, error in
				isLoading = false
				if let error = error {
					debugPrint("Error fetching top data:", error.localizedDescription)
				} else if let result = result {
					self.topDatas = result
				}
			}
		} else {
			// 根据搜索词加载数据
			cloud.fetchByPromptContaining(searchText) { result, nextCursor, error in
				isLoading = false
				if let error = error {
					debugPrint("Error fetching data with search text:", error.localizedDescription)
				} else if let result = result {
					self.datas = result
					self.cursor = nextCursor
				}
			}
		}
	}
	
	// 刷新数据
	private func refreshData() {
		datas.removeAll()
		topDatas.removeAll()
		cursor = nil
		loadInitialData()
	}
	
	// 分页加载更多数据
	private func loadMore(cursor: CKQueryOperation.Cursor) {
		isLoading = true
		cloud.fetchByPromptContaining(searchText, cursor: cursor) { result, nextCursor, error in
			isLoading = false
			if let error = error {
				debugPrint("Error fetching more data:", error.localizedDescription)
			} else if let result = result {
				self.datas += result
				self.cursor = nextCursor
			}
		}
	}
}




#Preview {
	CloudRingTongsView()
}


