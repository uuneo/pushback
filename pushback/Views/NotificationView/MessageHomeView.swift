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
	
	@ObservedResults(Message.self) var messagesAll
	@Default(.appIcon) private var appicon
	
	@State private var showAction = false
	@State private var helpviewSize:CGSize = .zero
	@State private var searchText:String = ""
	@State private var showExample:Bool = false

	
	
	var groupMessages:[Message]{
		messagesAll.reduce(into: [String: [Message]]()) { result, message in
			// 根据 group 分类
			result[message.group, default: []].append(message)
		}
		.map { group, messages in
			messages.sorted(by: { $0.createDate > $1.createDate }).first!
		}
		.sorted{$0.createDate > $1.createDate}
	}

	
	var body: some View {
		NavigationStack{
			List {
				
				if searchText.isEmpty{
					ForEach(groupMessages,id: \.id){ message in
						
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
							
						}
						
						
						
					}.onDelete(perform: { indexSet in
						for index in indexSet{
							RealmManager.shared.delete( groupMessages[index].group)
						}
					})
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
		
		
		if messagesAll.count == 0{
			Toast.shared.present(title: "没有消息", symbol: .error)
			return
		}
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
		messagesAll.filter {$0.group == message.group && !$0.read}.count
	}



	private func groupBody(_ message: Message)-> some View{

		if let title = message.title, let subtitle = message.subtitle{
			return  Text("\(title) - ") + Text("\(subtitle)；") + Text(message.body ?? "")

		}

		if let title = message.title{
			return  Text("\(title)；") + Text(message.body ?? "")
		}

		if let subtitle = message.subtitle{
			return  Text("\(subtitle)；") + Text(message.body ?? "")
		}

		return Text(message.body ?? "")
	}


	
}

#Preview {
    MessageHomeView()
}
