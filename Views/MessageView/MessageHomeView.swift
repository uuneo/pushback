//
//  File name:     MessageHomeView.swift
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Blog  :        https://uuneo.com
//  E-mail:        to@uuneo.com

//  Description:

//  History:
//  Created by uuneo on 2024/12/5.


import SwiftUI
import RealmSwift
import Defaults

struct MessageHomeView: View {
	@EnvironmentObject private var manager:PushbackManager
	@Environment(\.isSearching) var isSearching

	@ObservedSectionedResults(Message.self,
							  sectionKeyPath: \.group,
							  sortDescriptors: [SortDescriptor(keyPath: \Message.createDate, ascending: false)]) var messages


	@Default(.appIcon) private var appicon

	@State private var showAction = false
	@State private var helpviewSize:CGSize = .zero
	@State private var searchText:String = ""
	@State private var showExample:Bool = false

	var body: some View {
		NavigationStack{
			List {

				if searchText.isEmpty{
					ForEach(messages,id: \.id){ groupMessage in
						if let message = groupMessage.first{
							NavigationLink {

								MessagesView(group: message.group)
									.toolbar(.hidden, for: .tabBar)
									.navigationTitle(message.group)



							} label: {
								MessageRow(message: message, unreadCount: unRead(message))

									.swipeActions(edge: .leading) {
										Button {

											Task{ RealmManager.shared.read(message.group) }

										} label: {

											Label( "标记", systemImage: unRead(message) == 0 ?  "envelope.open" : "envelope")
												.symbolRenderingMode(.palette)
												.foregroundStyle(.white, Color.primary)

										}.tint(.blue)
									}
									.swipeActions(edge: .trailing) {
										Button {
											Task{
												RealmManager.shared.delete(group: message.group)
											}

										} label: {

											Label( "删除", systemImage: "trash")
												.symbolRenderingMode(.palette)
												.foregroundStyle(.white, Color.primary)

										}.tint(.red)
									}


							}

						}



					}
				}else{
					SearchMessageView(searchText: searchText)
				}


			}
			.listRowSpacing(10)
			.navigationTitle( "信息")
			.navigationDestination(isPresented: $showExample){
				ExampleView()
					.toolbar(.hidden, for: .tabBar)
			}
			.onReceive(NotificationCenter.default.publisher(for: .messagePreview)) { _ in
				// 接收到通知时的处理
				self.showExample = false
			}

			.tipsToolbar(wifi: MonitorsManager.shared.isConnected, notification: MonitorsManager.shared.isAuthorized, callback: {
				manager.openSetting()
			})
			.toolbar{

				ToolbarItem{

					Button{
						self.showExample.toggle()
					}label:{
						Image(systemName: "questionmark.circle")
							.symbolRenderingMode(.palette)
							.foregroundStyle(.green, Color.primary)
					}

				}


				ToolbarItem {



					if ISPAD{
						Menu {
							ForEach( MessageAction.allCases, id: \.self){ item in
								Button{
									deleteMessage(item)
								}label:{
									Label(item.localized, systemImage: (item == .cancel ? "arrow.uturn.right.circle" : item == .markRead ? "text.badge.checkmark" : "xmark.bin.circle"))
										.symbolRenderingMode(.palette)
										.foregroundStyle(.green, Color.primary)
								}
							}
						} label: {
							Image(systemName: "trash.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.green, Color.primary)
						}


					}else{

						Button{
							self.showAction = true
						}label: {
							Image(systemName: "trash.circle")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.green, Color.primary)

						}


					}

				}


			}
		
			.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
			.actionSheet(isPresented: $showAction) {

				ActionSheet(title: Text( "删除以下时间的信息!"),
							buttons: MessageAction.allCases.map({ item in

					switch item{
						case .cancel:
							Alert.Button.cancel()
						case .markRead:
							Alert.Button.default(Text(item.localized), action: {
								deleteMessage(item)
							})
						default:
							Alert.Button.destructive(Text(item.localized), action: {
								deleteMessage(item)
							})
					}

				}))
			}

		}
	}



	func deleteMessage(_ mode: MessageAction){
		switch mode {
			case .markRead:
				RealmManager.shared.read()
			case .cancel:
				break
			default:
				RealmManager.shared.delete(mode.date)
		}

		Toast.shared.present(title: "删除成功", symbol: .success)

	}

	@ViewBuilder
	func MessageRow(message: Message,unreadCount: Int )-> some View{
		HStack {
			if unreadCount > 0 {
				Circle()
					.fill(Color.blue)
					.frame(width: 10, height: 10)
			}

			AvatarView(id: message.id.uuidString, icon: message.icon, mode: message.mode)
				.frame(width: 45, height: 45)
				.clipped()
				.clipShape(RoundedRectangle(cornerRadius: 10))


			VStack(alignment: .leading) {
				HStack {
					Text(message.group)
						.font(.headline.bold())
						.foregroundStyle(.textBlack)

					Spacer()

					Text(message.createDate.agoFormatString())
						.foregroundStyle(message.createDate.colorForDate())
						.font(.caption2)
				}

				groupBody(message)
					.font(.footnote)
					.lineLimit(2)
					.foregroundStyle(.gray)
			}
		}
	}


	private func unRead(_ message: Message) -> Int{
		do{
			return try Realm().objects(Message.self).where({$0.group == message.group && !$0.read}).count
		}catch{
			return 0
		}

	}



	private func groupBody(_ message: Message)-> some View{

		if let title = message.title, let subtitle = message.subtitle{
			return  Text("\(title)" + " - ") + Text("\(subtitle)" + "；") + Text(message.body ?? "")

		}

		if let title = message.title{
			return  Text("\(title)" + "；") + Text(message.body ?? "")
		}

		if let subtitle = message.subtitle{
			return  Text("\(subtitle)" + "；") + Text(message.body ?? "")
		}

		return Text(message.body ?? "")
	}



}

#Preview {
	MessageHomeView()
}
