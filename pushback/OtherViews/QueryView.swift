//
//  QueryView.swift
//  pushback
//
//  Created by He Cho on 2024/10/16.
//

import SwiftUI
import SwiftData
import Foundation


@available(iOS 17, *)
struct QueryView<Model: PersistentModel, Content: View>: View {
	
	@Query private var query: [Model]
	private var content: ([Model]) -> (Content)
	
	init(for type: Model.Type,
		 sort: [Foundation.SortDescriptor<Model>] = [],
		 @ViewBuilder content: @escaping ([Model]) -> Content,
		 filter: (() -> (Predicate<Model>))? = nil) {
		_query = Query(filter: filter?(), sort: sort)
		self.content = content
	}
	
	var body: some View {
		content(query)
	}
}


@available(iOS 17, *)
struct SectionedQueryView<Content: View, Model: PersistentModel, Key: Hashable>: View {
	@Query private var query: [Model]
	private var content: ([QueryViewDataSection<Key, Model>]) -> Content
	private var keyExtractor: ((Model) -> Key)
	
	init(for type: Model.Type,
		 sectionedBy keyExtractor: @escaping ((Model) -> Key),
		 sort: [Foundation.SortDescriptor<Model>] = [],
		 @ViewBuilder content: @escaping ([QueryViewDataSection<Key, Model>]) -> Content,
		 filter: (() -> (Predicate<Model>))? = nil) {
		_query = Query(filter: filter?(), sort: sort)
		self.content = content
		self.keyExtractor = keyExtractor
	}
	
	var body: some View {
		let data = Dictionary(grouping: query, by: keyExtractor)
		let result = keys.reduce([QueryViewDataSection]()) { partialResult, key in
			partialResult + [.init(key: key, models: data[key] ?? [])]
		}
		content(result)
	}
	
	private var keys: [Key] {
		var seen: Set<Key> = []
		var result: [Key] = []
		
		for model in query {
			let key = keyExtractor(model)
			if !seen.contains(key) {
				seen.insert(key)
				result.append(key)
			}
		}
		
		return result
	}
	
}

@available(iOS 17, *)
struct QueryViewDataSection<Key: Hashable, Model: PersistentModel>: Identifiable , Hashable{
	let key: Key
	let models: [Model]
	let id = UUID()
	
}

