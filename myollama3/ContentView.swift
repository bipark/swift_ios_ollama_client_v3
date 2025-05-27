//
//  ContentView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI


struct ContentView: View {
    @State private var path = NavigationPath()
    @State private var conversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
    @State private var allConversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {

                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .imageScale(.large)
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appPrimary)
                    
                    Button(action: {
                        path.append("New\(UUID().uuidString)")
                    }) {
                        Text("l_new_conversation".localized)
                            .padding()
                            .background(Color.appPrimary)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .font(.headline)
                    }
                }
                .padding()
                
                Divider()
                
                RecentConversationsView(
                    conversations: filteredConversations,
                    isLoading: isLoading,
                    searchText: $searchText,
                    isSearching: $isSearching,
                    onReload: loadConversations,
                    onConversationSelected: { conversationId in
                        path.append("Old\(conversationId)")
                    },
                    onDelete: deleteConversation,
                    onSearch: searchConversations
                )
                .frame(maxHeight: .infinity)
            }
            .frame(minWidth: 300, minHeight: 400)
            .navigationTitle("l_my_ollama".localized)
            .navigationDestination(for: String.self) { destination in
                if destination.hasPrefix("New") {
                    ChatView()
                } else if destination.hasPrefix("Old") {
                    let conversationId = String(destination.dropFirst(3))

                    let conversation = conversations.first { $0.id == conversationId }
                    let baseUrl = conversation?.baseUrl != nil ? URL(string: conversation!.baseUrl!) : nil
                    
                    ChatView(conversationId: conversationId, baseUrl: baseUrl)
                } else if destination == "Settings" {
                    SettingsView()
                }
            }
            .alert("l_error".localized, isPresented: $showError) {
                Button("l_ok".localized, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadConversations()
                
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("ConversationDataChanged"),
                    object: nil,
                    queue: .main
                ) { _ in
                    loadConversations()
                }
            }
            .refreshable {
                loadConversations()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { path.append("Settings") }) {
                        Image(systemName: "gear")
                            .foregroundColor(Color.appIcon)
                    }
                }
            }
        }
    }
    
    private var filteredConversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] {
        if searchText.isEmpty {
            return allConversations
        } else {
            return conversations
        }
    }
    
    private func getServerName(from urlString: String) -> String {
        if let url = URL(string: urlString) {
            let host = url.host ?? "l_unknown_server".localized
            return "\(host):\(url.port ?? 0)"
        }
        return "l_unknown_server".localized
    }
    
    private func loadConversations() {
        isLoading = true
        
        Task {
            do {

                let service = OllamaService()
                let loadedConversations = try await service.getAllConversations()
                
                await MainActor.run {
                    self.conversations = loadedConversations
                    self.allConversations = loadedConversations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(format: "l_cannot_load_conversations".localized, error.localizedDescription)
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func searchConversations() {
        guard !searchText.isEmpty else {
            conversations = allConversations
            return
        }
        
        Task {
            do {
                let service = OllamaService()
                let searchResults = try await service.searchAllConversations(searchText: searchText)
                
                await MainActor.run {
                    self.conversations = searchResults
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = String(format: "l_cannot_load_conversations".localized, error.localizedDescription)
                    self.showError = true
                }
            }
        }
    }
    
    private func deleteConversation(at offsets: IndexSet) {
        let idsToDelete = offsets.map { conversations[$0].id }
        
        Task {
            do {

                let service = OllamaService()
                
                for id in idsToDelete {
                    try await service.deleteConversation(groupId: id)
                }
                
                loadConversations()
            } catch {
                await MainActor.run {
                    self.errorMessage = String(format: "l_cannot_delete_conversation".localized, error.localizedDescription)
                    self.showError = true
                }
            }
        }
    }
}


struct RecentConversationsView: View {
    let conversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)]
    let isLoading: Bool
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onReload: () -> Void
    let onConversationSelected: (String) -> Void
    let onDelete: (IndexSet) -> Void
    let onSearch: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if conversations.count > 0 {
                HStack {
                    Text("l_recent_conversations".localized)
                        .font(.headline)
                    
                    Spacer()
                    

                    Button(action: {
                        withAnimation {
                            isSearching.toggle()
                            if !isSearching {
                                searchText = ""
                                onSearch()
                            }
                        }
                    }) {
                        Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: onReload) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("l_search_conversations".localized, text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            onSearch()
                        }
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            if isLoading {
                ProgressView("l_loading_conversations".localized)
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if conversations.isEmpty {
                if isSearching && !searchText.isEmpty {
                    Text("l_no_search_results".localized)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("l_no_saved_conversations".localized)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            } else {
                List {
                    ForEach(conversations, id: \.id) { conversation in
                        ConversationItemView(
                            conversation: conversation,
                            onTap: {
                                onConversationSelected(conversation.id)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: onDelete)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
    }
}


struct ConversationRow: View {
    let conversation: (id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)
    var isPressed: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {

            if let imageBase64 = conversation.image, let uiImage = convertBase64ToImage(imageBase64) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(Color.appIcon)
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {

                Text(conversation.firstQuestion)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if !conversation.firstAnswer.isEmpty {
                    Text(conversation.firstAnswer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {

                    Text(dateFormatter.string(from: conversation.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let engine = conversation.engine {
                        Spacer()

                        Text(engine)
                            .font(.caption2)
                            .foregroundColor(Color.appPrimary.opacity(0.7))
                    }
                }
            }
            .padding(.vertical, 4)            
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isPressed ? Color.gray.opacity(0.15) : Color.gray.opacity(0.05))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    private func convertBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            print("Base64 decoding failed")
            return nil
        }
        
        return UIImage(data: imageData)
    }
}


struct ConversationItemView: View {
    let conversation: (id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ConversationRow(conversation: conversation, isPressed: isPressed)
            .contentShape(Rectangle())
            .onTapGesture {

                isPressed = true
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false

                    onTap()
                }
            }
    }
}

