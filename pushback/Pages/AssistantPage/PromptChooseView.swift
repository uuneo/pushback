

import SwiftUI
import Foundation
import RealmSwift

// MARK: - Views
/// 提示词选择视图
struct PromptChooseView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedResults(ChatPrompt.self) var prompts
    
    @State private var isAddingPrompt = false
    @State private var searchText = ""
    @State private var selectedPrompt: ChatPrompt? = nil


    private var filteredBuiltInPrompts: [ChatPrompt] {
        Array(prompts.where({$0.isBuiltIn}))
    }

    private var filteredCustomPrompts: [ChatPrompt] {
        guard !searchText.isEmpty else { return prompts.filter({!$0.isBuiltIn}) }
        return prompts.filter({!$0.isBuiltIn}).filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var hasSearchResults: Bool {
        !searchText.isEmpty && filteredBuiltInPrompts.isEmpty && filteredCustomPrompts.isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            promptListView
                .navigationTitle("选择提示词")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer,
                    prompt: "搜索提示词"
                )
                .toolbar {
                    toolbarContent
                    addPromptButton
                }
        }
    }

    // MARK: - View Components
    private var promptListView: some View {
        List {
            if hasSearchResults {
                if #available(iOS 17.0, *){
                    ContentUnavailableView("没有找到相关提示词", systemImage: "magnifyingglass")
                }else{
                    VStack{
                        HStack{
                            Spacer()
                            Image("magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .padding()
                            Spacer()
                        }
                        Spacer()
                        HStack{
                            Spacer()
                            Text("没有找到相关提示词")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding()
                            Spacer()
                        }
                    }.frame(height: 300)
                }

            } else {
                promptSections
            }
        }
        .sheet(isPresented: $isAddingPrompt) {
            AddPromptView()
                .customPresentationCornerRadius(20)
        }
    }

    private var promptSections: some View {
        Group {
            if !filteredBuiltInPrompts.isEmpty {
                PromptSection(
                    title: String(localized: "内置提示词"),
                    prompts: filteredBuiltInPrompts,
                    onPromptTap: handlePromptTap
                )
            }

            if !filteredCustomPrompts.isEmpty {
                PromptSection(
                    title: String(localized: "自定义提示词"),
                    prompts: filteredCustomPrompts,
                    onPromptTap: handlePromptTap
                )
            }
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消", role: .cancel) {
                    dismiss()
                }
            }
        }
    }
    
    private var addPromptButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isAddingPrompt = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    

    // MARK: - Methods
    private func handlePromptTap(_ prompt: ChatPrompt) {
        
        
        RealmManager.handler { realm in
            
            let results = realm.objects(ChatPrompt.self)
            
            let selected = results.where({$0.id == prompt.id})
            let noSelected = results.where({$0.id != prompt.id})
            
            realm.writeAsync {
                selected.setValue(true, forKey: "isSelected")
                noSelected.setValue(false, forKey: "isSelected")
            }
            
        }
        dismiss()
    }
}

// MARK: - PromptSection
private struct PromptSection: View {
    let title: String
    let prompts: [ChatPrompt]
    let onPromptTap: (ChatPrompt) -> Void
    
    @State private var showDeleteAlert = false
    @State private var promptToDelete: ChatPrompt?

    var body: some View {
        Section(title) {
            ForEach(prompts) { prompt in
                PromptRowView(prompt: prompt)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPromptTap(prompt)
                    }
                    .modifier(PromptSwipeActions(
                        prompt: prompt,
                        showDeleteAlert: $showDeleteAlert,
                        promptToDelete: $promptToDelete
                    ))
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert, presenting: promptToDelete) { prompt in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let prompt = promptToDelete{
                
                    RealmManager.handler { realm in
                        if let datas = realm.objects(ChatPrompt.self).first(where: {$0.id == prompt.id}){
                            realm.writeAsync {
                                realm.delete(datas)
                            }
                          
                        }
                       
                    }
                }
               
            }
        } message: { prompt in
            Text("确定要删除\"\(prompt.title)\"提示词吗？此操作无法撤销。")
        }
    }
}

// MARK: - PromptRowView
private struct PromptRowView: View {
    let prompt: ChatPrompt

    var body: some View {
        HStack(spacing: 12) {
            // 选中状态指示器
            Circle()
                .fill(prompt.isSelected ? Color.blue : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .strokeBorder(
                            prompt.isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )

            // 提示词内容
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(prompt.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if prompt.isBuiltIn {
                        Text("内置")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }

                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
}

// MARK: - PromptSwipeActions
private struct PromptSwipeActions: ViewModifier {
    let prompt:  ChatPrompt
    @Binding var showDeleteAlert: Bool
    @Binding var promptToDelete:  ChatPrompt?


    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
               
                // 编辑按钮
                NavigationLink {
                    PromptDetailView(prompt: prompt)
                } label: {
                    Label("查看", systemImage: "eye")
                }
                .tint(.blue)
            }
            .if(!prompt.isBuiltIn) { view in
                view
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            promptToDelete = prompt
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        
        
    }
}

// MARK: - PromptButtonView
struct PromptButtonView: View {
    // MARK: - Properties
    @State private var showPromptChooseView = false
    @State private var selectedPromptIndex: Int?
    
    
    // MARK: - Body
    var body: some View {
        Button {
            showPromptChooseView = true
        } label: {
            Image(systemName: "text.bubble")
                .foregroundColor(.blue)
                .padding(.trailing, 8)
        }
        .sheet(isPresented: $showPromptChooseView) {
            PromptChooseView()
                .customPresentationCornerRadius(20)
        }
    }
}


// MARK: - 添加Prompt视图
struct AddPromptView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var address = ""

    
    // MARK: - View
    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("网络地址", text: $address)
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            .navigationTitle("添加 Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        
                        let chatprompt = ChatPrompt()
                        chatprompt.title = title
                        chatprompt.content = content
                        chatprompt.address = address
                        chatprompt.isBuiltIn = false
                        
                        RealmManager.handler { realm in
                            realm.writeAsync {
                                realm.add(chatprompt)
                               
                            }onComplete: { _ in
                                self.dismiss()
                            }
                            
                           
                        }
                      
                    }
                    .disabled(!(!title.isEmpty && !content.isEmpty))
                }
            }
        }
    }
    
}



// MARK: - Preview
#Preview("提示词选择") {
    PromptChooseView()
}
