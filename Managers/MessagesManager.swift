//
//  MessagesManager.swift
//  pushback
//
//  Created by lynn on 2025/5/26.
//
import Foundation
import GRDB

class MessagesManager: ObservableObject{
    static let shared =  MessagesManager()
    
    private let DB: DatabaseManager = DatabaseManager.shared
    private var observationCancellable: AnyDatabaseCancellable?
    
    @Published var unreadCount: Int = 0
    @Published var allCount: Int = 1000000
    @Published var updateSign:Int = 0
    @Published var groupMessages: [Message] = []
    @Published var singleMessages: [Message] = []
    @Published var showGroupLoading:Bool = false
    
    private init() { startObservingUnreadCount() }
    
    deinit{ observationCancellable?.cancel() }
    
    private func startObservingUnreadCount() {
        let observation = ValueObservation.tracking { db -> (Int,Int) in
            let unRead = try Message.filter(Column("read") == false).fetchCount(db)
            let count = try Message.fetchCount(db)
            return (unRead,count)
        }
        
        observationCancellable = observation.start(
            in: DB.dbPool,
            scheduling: .async(onQueue: .global()),
            onError: { error in
                Log.error("Failed to observe unread count:", error)
            },
            onChange: { [weak self] newUnreadCount in
                DispatchQueue.main.async {
                    self?.showGroupLoading = true
                    self?.updateSign += 1
                    self?.unreadCount = newUnreadCount.0
                    self?.allCount = newUnreadCount.1
                }
                Task.detached(priority: .userInitiated) { [unowned self] in
                    await self?.updateGroup()
                    await MainActor.run {
                        self?.showGroupLoading = false
                    }
                }
            }
        )
    }
    
    func updateGroup() async {
        let results = await DB.queryGroup()
        let count  = DB.count()
        let unCount = DB.unreadCount()
        await MainActor.run {
            self.groupMessages = results
            self.updateSign += 1
            self.allCount = count
            self.unreadCount = unCount
        }
    }

    
}
