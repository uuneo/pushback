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
	@State private var itemsPerPage: Int = 50 // 每页加载50条数据
	@State private var isLoading: Bool = false
	@State private var selectMessage:Message?
	@State private var selectUserInfo:Message?
	var body: some View {

		List {
			if searchText.isEmpty{
				ForEach(messages.prefix(currentPage * itemsPerPage), id: \.id) { message in

					MessageView(message: message, searchText: searchText){ mode in

						switch mode{
							case .image:
								if let imageUrl = message.image.first{
									if let imageModel = images.first(where: { $0.url == imageUrl}){
										withAnimation {
											self.imageDetail = imageModel
										}

									}else {
										Task{
											if let _ = await ImageManager.downloadImage(imageUrl),
											   let imageModel = images.first(where: { $0.url == imageUrl}){
												DispatchQueue.main.async{
													withAnimation(.easeInOut) {
														self.imageDetail = imageModel
													}
												}

											}

										}
									}
								}
							case .text:
								withAnimation(.easeInOut) {
									self.selectMessage = message
								}
							case .userInfo:
								withAnimation(.easeInOut) {
									self.selectUserInfo = message
								}
						}

					}
					.onAppear{
						if messages.prefix(currentPage * itemsPerPage).last == message{

							currentPage = min(Int(ceil(Double(messages.count) / Double(itemsPerPage))), currentPage + 1)
						}
					}
					.listRowBackground(Color.clear)
					.listSectionSeparator(.visible)


				}.onDelete(perform: $messages.remove)
					.opacity((selectMessage != nil || selectUserInfo != nil || imageDetail != nil) ? 0.01 : 1)
			}else{
				SearchMessageView(searchText: searchText, group: group ?? "")
			}
		}
		.navigationBarHidden((selectMessage != nil || selectUserInfo != nil || imageDetail != nil))
		.overlay {
			if let imageDetail {
				ImageDetailView(image: imageDetail,imageUrl: $imageDetail )
					.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
					.transition(.opacity)

			}

		}
		.overlay{
			if let message =  selectMessage{
				ScrollView{

					ZStack{

						VStack{
							HStack{
								Spacer(minLength: 0)
								Text(message.title ?? "")
									.font(.title3.bold())
									.textSelection(.enabled)
								Spacer(minLength: 0)
							}

							HStack{
								Spacer(minLength: 0)
								Text(message.subtitle ?? "")
									.font(.headline.bold())
									.textSelection(.enabled)
								Spacer(minLength: 0)
							}

							Line()
								.stroke(.gray, style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, dash: [7]))
								.frame(height: 1)
								.padding(.horizontal, 5)

							HStack{

								Text(message.body ?? "")
									.textSelection(.enabled)
								Spacer(minLength: 0)
							}
						}
						.frame(width: UIScreen.main.bounds.width - 50)
					}
					.frame(width: UIScreen.main.bounds.width)
					.frame(minHeight: UIScreen.main.bounds.height)


				}
				
				.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
				.background(.ultraThinMaterial)
				.containerShape(RoundedRectangle(cornerRadius: 0))
				.onTapGesture {
					withAnimation(.easeInOut) {
						self.selectMessage = nil
					}
				}

				.transition(.opacity)
			}
		}
		.overlay{
			if let message = selectUserInfo{
				ScrollView{
					ZStack{
						Text(message.userInfo)
							.textSelection(.enabled)
							.padding()
					}

					.frame(width: UIScreen.main.bounds.width)
					.frame(minHeight: UIScreen.main.bounds.height)

				}
				.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
				.background(.ultraThinMaterial)
				.containerShape(RoundedRectangle(cornerRadius: 0))
				.onTapGesture {
					withAnimation(.easeInOut)  {
						self.selectUserInfo = nil
					}
				}
				.transition(.opacity)
			}
		}
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
		.toolbar{
			ToolbarItem {
				Text("\(min(currentPage * itemsPerPage, messages.count))/\(messages.count)")
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