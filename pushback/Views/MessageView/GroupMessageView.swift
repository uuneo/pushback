//
//  GroupMessageView.swift
//  pushback
//
//  Created by He Cho on 2024/10/8.
//

import SwiftUI
import RealmSwift
import Defaults

struct GroupMessageView: View {
	
	@ObservedResults(Message.self) var messagesAll
	@EnvironmentObject private var manager:PushbackManager
	@Environment(\.isSearching) var isSearching
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
				
				
				ForEach(groupMessages,id: \.id){ message in
					
					NavigationLink {
						
						MessagesView(group: message.group)
							.toolbar(.hidden, for: .tabBar)
							.navigationTitle(message.group)
					} label: {
						MessageRow(message: message, unreadCount: unRead(message))
							.swipeActions(edge: .leading) {
								Button {
									
									Task{ RealmProxy.shared.read(message.group) }
									
								} label: {
									
									Label( "标记", systemImage: unRead(message) == 0 ?  "envelope.open" : "envelope")
										.symbolRenderingMode(.palette)
										.foregroundStyle(.white, Color.primary)
									
								}.tint(.blue)
							}
						
					}
					
					
					
				}.onDelete(perform: { indexSet in
					for index in indexSet{
						RealmProxy.shared.delete( groupMessages[index].group)
					}
				})
			}
			.listStyle(.plain)
			.navigationTitle( "信息")
			
			.navigationDestination(isPresented: $showExample){
				ExampleView()
					.toolbar(.hidden, for: .tabBar)
			}
			.onReceive(NotificationCenter.default.publisher(for: .messagePreview)) { _ in
				// 接收到通知时的处理
				self.showExample = false
			}
			
			.tipsToolbar(wifi: Monitors.shared.isConnected, notification: Monitors.shared.isAuthorized, callback: {
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
			.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic)){
				SearchMessageView(searchText: searchText)
			}
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
			RealmProxy.shared.read()
		case .cancel:
			break
		default:
			RealmProxy.shared.delete(mode.date)
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
						.font(.headline.weight(.bold))
						.foregroundStyle(.textBlack)
					
					Spacer()
					
					Text(message.createDate.agoFormatString())
						.font(.caption2)
				}
				
				HStack {
					if let title = message.title {
						Text("【\(title)】\(message.body ?? "")")
					} else {
						Text(message.body ?? "")
					}
				}
				.font(.footnote)
				.lineLimit(2)
				.foregroundStyle(.gray)
			}
		}
	}
	
	
	private func unRead(_ message: Message) -> Int{
		messagesAll.filter {$0.group == message.group && !$0.read}.count
	}
	
	
}


#Preview {
	GroupMessageView()
}
