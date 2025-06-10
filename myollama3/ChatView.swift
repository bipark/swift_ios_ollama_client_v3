//
//  ChatView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import MarkdownUI
import RegexBuilder
import Toasts
import PhotosUI
import Combine


typealias Message = LLMBridge.Message

struct ChatView: View {
    @StateObject private var llmBridge: LLMBridge
    
    @State private var newMessage = ""
    @State private var selectedModel: String
    @State private var availableModels: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isNewConversation: Bool
    @State private var showDeleteConfirmation = false
    @State private var messageToDelete: UUID?
    @State private var isModelLoadingFailed = false
    @State private var isModelLoading = true
    @Environment(\.presentToast) var presentToast
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPDFText: String? = nil
    @State private var selectedTXTText: String? = nil
    @State private var showShareAllSheet = false
    @StateObject private var settings = SettingsManager()
    @State private var selectedLLM: LLMTarget = .ollama
    @State private var llmBridgeForInput: LLMBridge
    
    // Database and conversation management
    private let databaseService = DatabaseService()
    private let conversationId: String
    
    private let selectedModelKey = "selected_model"
    private let defaultModel = "llama"
    
    init(conversationId: String? = nil) {
        let initialBridge = LLMBridge()
        _llmBridge = StateObject(wrappedValue: initialBridge)
        _llmBridgeForInput = State(initialValue: LLMBridge())
        
        self.conversationId = conversationId ?? UUID().uuidString
        _isNewConversation = State(initialValue: conversationId == nil)
        
        if let modelName = UserDefaults.standard.string(forKey: selectedModelKey) {
            _selectedModel = State(initialValue: modelName)
        } else {
            _selectedModel = State(initialValue: defaultModel)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(llmBridge.messages) { message in
                            MessageBubble(
                                message: message,
                                allMessages: llmBridge.messages,
                                onDelete: {
                                    messageToDelete = message.id
                                    showDeleteConfirmation = true
                                }
                            )
                            .dismissKeyboardOnTap(focusState: $isInputFocused)
                        }
                        
                        if !llmBridge.currentResponse.isEmpty {
                            HStack {
                                Markdown(llmBridge.currentResponse)
                                    .padding(12)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Spacer()
                            }
                            .id("currentResponse")
                            .transition(.opacity)
                            .dismissKeyboardOnTap(focusState: $isInputFocused)
                        }
                        
                        if llmBridge.isLoading && llmBridge.currentResponse.isEmpty {
                            HStack {
                                Text("l_thinking".localized)
                                    .padding(12)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Spacer()
                                
                                Button {
                                    llmBridge.cancelGeneration()
                                } label: {
                                    Text("l_cancel_generation".localized)
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.vertical, 4)
                            .dismissKeyboardOnTap(focusState: $isInputFocused)
                        }
                        
                        if let error = llmBridge.errorMessage {
                            HStack {
                                Text(String(format: "l_error_prefix".localized, error))
                                    .padding(12)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .dismissKeyboardOnTap(focusState: $isInputFocused)
                        }
                    }
                    .padding()
                    .onChange(of: llmBridge.messages.count) { _ in
                        if let lastMessage = llmBridge.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: llmBridge.currentResponse) { _ in
                        if !llmBridge.currentResponse.isEmpty {
                            withAnimation {
                                proxy.scrollTo("currentResponse", anchor: .bottom)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded {
                    hideKeyboard()
                    isInputFocused = false
                })
                .safeAreaInset(edge: .bottom) {
                    if !isModelLoading && !isModelLoadingFailed {
                        VStack(spacing: 0) {
                            Divider()
                            
                            MessageInputView(
                                text: $newMessage,
                                isLoading: llmBridge.isLoading,
                                shouldFocus: isNewConversation,
                                onSend: sendMessage,
                                selectedImage: $selectedImage,
                                selectedPDFText: $selectedPDFText,
                                selectedTXTText: $selectedTXTText,
                                isInputFocused: $isInputFocused,
                                selectedLLM: $selectedLLM,
                                selectedModel: $selectedModel,
                                enabledLLMs: settings.getEnabledLLMs(),
                                llmBridge: llmBridgeForInput,
                                onLLMChanged: handleLLMChanged
                            )
                            .environmentObject(settings)
                            .background(Color(.systemBackground))
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            hideKeyboard()
            isInputFocused = false
        })
        .navigationTitle(selectedModel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if !availableModels.isEmpty {
                    Menu {
                        ForEach(availableModels, id: \.self) { model in
                            Button(action: {
                                let oldModel = selectedModel
                                selectedModel = model
                                saveSelectedModel(model)
                                if !llmBridge.messages.isEmpty && oldModel != model {
                                    alertMessage = String(format: "l_model_changed".localized, selectedModel)
                                    presentToast(
                                        ToastValue(
                                            icon: Image(systemName: "info.circle"), message: alertMessage
                                        )
                                    )
                                }
                            }) {
                                HStack {
                                    Text(model)
                                    Spacer()
                                    if selectedModel == model {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color.appPrimary)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedModel)
                                .font(.headline)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color.appIcon)
                        }
                    }
                } else {
                    Text("l_conversation".localized)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if !llmBridge.messages.isEmpty {
                        showShareAllSheet = true
                    } else {
                        presentToast(
                            ToastValue(
                                icon: Image(systemName: "info.circle"), 
                                message: "l_no_conversations".localized
                            )
                        )
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color.appIcon)
                }
            }
        }
        .onAppear {
            isInputFocused = isNewConversation
            
            isModelLoading = true
            isModelLoadingFailed = false
            
            loadAvailableModels()
            loadConversationHistory()
            
            setupNotificationObservers()
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .alert("l_delete_message".localized, isPresented: $showDeleteConfirmation) {
            Button("l_cancel".localized, role: .cancel) {}
            Button("l_delete".localized, role: .destructive) {
                if let id = messageToDelete {
                    deleteMessage(id: id)
                }
            }
        } message: {
            Text("l_delete_message_confirm".localized)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("l_ok".localized, role: .cancel) {}
        }
        .sheet(isPresented: $showShareAllSheet) {
            ShareSheet(activityItems: [formatAllMessages()])
        }
    }
        
    private func loadAvailableModels() {
        Task {
            do {
                async let modelsTask = getAvailableModels()
                async let lastModelTask = getLastUsedModel()
                
                let models = try await modelsTask
                let lastUsedModel = await lastModelTask
                
                await MainActor.run {
                    self.availableModels = models
                    
                    if !models.isEmpty {
                        if !isNewConversation, let lastModel = lastUsedModel, models.contains(lastModel) {
                            selectedModel = lastModel
                            saveSelectedModel(lastModel)
                        } else if models.contains(selectedModel) {
                        } else {
                            selectedModel = models[0]
                            saveSelectedModel(selectedModel)
                        }
                    }
                    
                    self.isModelLoading = false
                    self.isModelLoadingFailed = false
                }
            } catch {
                print("l_models_error".localized, error.localizedDescription)
                await MainActor.run {
                    self.isModelLoading = false
                    self.isModelLoadingFailed = true
                    self.alertMessage = String(format: "l_cannot_load_models".localized, error.localizedDescription)
                    self.showAlert = true
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("sendMessage called - trimmedMessage: '\(trimmedMessage)'")
        print("selectedImage: \(selectedImage != nil)")
        print("selectedPDFText: \(selectedPDFText != nil)")
        print("selectedTXTText: \(selectedTXTText != nil)")
        
        if !trimmedMessage.isEmpty || selectedImage != nil || selectedPDFText != nil || selectedTXTText != nil {
            let imageToSend = selectedImage
            let pdfTextToSend = selectedPDFText
            let txtTextToSend = selectedTXTText
            selectedImage = nil
            selectedPDFText = nil
            selectedTXTText = nil
            
            var finalMessage = trimmedMessage
            
            if let pdfText = pdfTextToSend {
                print("Processing PDF text, length: \(pdfText.count)")
                if !finalMessage.isEmpty {
                    finalMessage += "\n\n[PDF 문서 내용]\n" + pdfText
                } else {
                    finalMessage = "[PDF 문서 내용]\n" + pdfText
                }
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                presentToast(
                    ToastValue(
                        icon: Image(systemName: "doc.text"), message: "PDF 문서가 첨부되었습니다"
                    )
                )
            }
            
            if let txtText = txtTextToSend {
                print("Processing TXT text, length: \(txtText.count)")
                print("TXT content preview: \(String(txtText.prefix(100)))...")
                if !finalMessage.isEmpty {
                    finalMessage += "\n\n[텍스트 파일 내용]\n" + txtText
                } else {
                    finalMessage = "[텍스트 파일 내용]\n" + txtText
                }
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                presentToast(
                    ToastValue(
                        icon: Image(systemName: "doc.plaintext"), message: "텍스트 파일이 첨부되었습니다"
                    )
                )
            }
            
            print("Final message to send: '\(finalMessage)'")
            
            newMessage = ""
            
            if imageToSend != nil {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                presentToast(
                    ToastValue(
                        icon: Image(systemName: "info.circle"), message: "l_image_attached".localized
                    )
                )
            }
            
            Task {
                do {
                    let message = try await llmBridge.sendMessage(
                        content: finalMessage, 
                        image: imageToSend, 
                        model: selectedModel
                    )
                    
                    // Save to database
                    await saveMessageToDatabase(
                        question: finalMessage,
                        answer: message.content,
                        image: imageToSend,
                        engine: selectedModel
                    )
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteMessage(id: UUID) {
        guard let index = llmBridge.messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        Task {
            do {
                try await deleteMessageFromDatabase(at: index)
                await MainActor.run {
                    // Remove from LLMBridge messages
                    let messageToRemove = llmBridge.messages[index]
                    let isUserMessage = messageToRemove.isUser
                    
                    var indicesToRemove: [Int] = []
                    
                    if isUserMessage && index + 1 < llmBridge.messages.count && !llmBridge.messages[index + 1].isUser {
                        indicesToRemove = [index, index + 1]
                    }
                    else if !isUserMessage && index > 0 && llmBridge.messages[index - 1].isUser {
                        indicesToRemove = [index - 1, index]
                    }
                    else {
                        indicesToRemove = [index]
                    }
                    
                    for i in indicesToRemove.sorted(by: >) {
                        llmBridge.messages.remove(at: i)
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = String(format: "l_cannot_delete_message".localized, error.localizedDescription)
                    showAlert = true
                }
            }
        }
    }
    
    private func saveSelectedModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: selectedModelKey)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OllamaServerURLChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let urlString = notification.userInfo?["url"] as? String,
               let url = URL(string: urlString) {
                // Note: URL이 변경되면 앱 재시작이 필요합니다
                // 현재 ChatView에서는 즉시 반영되지 않습니다
                
                isModelLoading = true
                isModelLoadingFailed = false
                loadAvailableModels()
            }
        }
    }
    
    private func formatAllMessages() -> String {
        var formattedText = "# \(selectedModel) \("l_conversation".localized)\n\n"
        
        if llmBridge.messages.isEmpty {
            return "l_no_conversations".localized
        }
        
        for (index, message) in llmBridge.messages.enumerated() {
            if message.isUser {
                formattedText += "## \(String(format: "l_question".localized, index/2 + 1))\n"
                var content = message.content
                
                if message.image != nil && content.isEmpty {
                    content = "l_image".localized
                } else if message.image != nil {
                    content = "\(content)\n\("l_image_attached".localized)"
                }
                
                formattedText += "\(content)\n\n"
            } else {
                formattedText += "### \("l_answer".localized)\n"
                formattedText += "\(message.content)\n\n"
                
                if index < llmBridge.messages.count - 1 {
                    formattedText += "---\n\n"
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date())
                
        return formattedText
    }
    
    // MARK: - Database Methods
    
    private func getAvailableModels() async throws -> [String] {
        let models = await llmBridge.getAvailableModels()
        return models.isEmpty ? [defaultModel] : models
    }
    
    private func loadConversationHistory() {
        Task {
            do {
                let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
                
                await MainActor.run {
                    llmBridge.messages.removeAll()
                    
                    for conversation in conversations {
                        var userImage: UIImage? = nil
                        if let imageBase64 = conversation.image {
                            userImage = convertBase64ToImage(imageBase64)
                        }
                        
                        let userMessage = LLMBridge.Message(content: conversation.question, isUser: true, image: userImage)
                        let aiMessage = LLMBridge.Message(content: conversation.answer, isUser: false, image: nil)
                        
                        llmBridge.messages.append(userMessage)
                        llmBridge.messages.append(aiMessage)
                    }
                }
            } catch {
                print(String(format: "l_conversation_history_error".localized, error.localizedDescription))
            }
        }
    }
    
    private func saveMessageToDatabase(question: String, answer: String, image: UIImage?, engine: String) async {
        do {
            var imageBase64: String? = nil
            if let image = image {
                imageBase64 = encodeImageToBase64(image)
            }
            
            try databaseService.saveQuestion(
                groupId: conversationId,
                instruction: nil,
                question: question,
                answer: answer,
                image: imageBase64,
                engine: engine,
                baseUrl: ""
            )
        } catch {
            print("Failed to save to database: \(error)")
        }
    }
    
    private func deleteMessageFromDatabase(at index: Int) async throws {
        let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
        
        guard index < llmBridge.messages.count else { return }
        
        let messageToRemove = llmBridge.messages[index]
        let isUserMessage = messageToRemove.isUser
        
        var indicesToRemove: [Int] = []
        
        if isUserMessage && index + 1 < llmBridge.messages.count && !llmBridge.messages[index + 1].isUser {
            indicesToRemove = [index, index + 1]
        }
        else if !isUserMessage && index > 0 && llmBridge.messages[index - 1].isUser {
            indicesToRemove = [index - 1, index]
        }
        else {
            indicesToRemove = [index]
        }
        
        guard let maxIndex = indicesToRemove.max(), maxIndex < conversations.count * 2 else {
            throw NSError(domain: "ChatView", code: 1, userInfo: [NSLocalizedDescriptionKey: "l_index_out_of_range".localized])
        }
        
        var createdTimesToDelete: [String] = []
        
        for idx in indicesToRemove {
            let dbIndex = idx / 2
            
            if dbIndex < conversations.count && !createdTimesToDelete.contains(conversations[dbIndex].created) {
                createdTimesToDelete.append(conversations[dbIndex].created)
            }
        }
        
        for created in createdTimesToDelete {
            try databaseService.deleteQuestion(groupId: conversationId, created: created)
        }
    }
    
    private func getLastUsedModel() async -> String? {
        guard !conversationId.isEmpty else { return nil }
        
        do {
            let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
            
            if let lastConversation = conversations.last {
                return lastConversation.engine
            }
            
            return nil
        } catch {
            print(String(format: "l_last_model_error".localized, error.localizedDescription))
            return nil
        }
    }
    
    private func convertBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            print("l_base64_decoding_failed".localized)
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private func encodeImageToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        let resizedImage = resizeImageIfNeeded(image, maxSize: 1024)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            print("l_image_compression_failed".localized)
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        if maxDimension <= maxSize {
            return image
        }
        
        let scaleFactor = maxSize / maxDimension
        let newWidth = size.width * scaleFactor
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private func createLLMBridge(for target: LLMTarget) -> LLMBridge {
        return LLMBridge()
    }
    
    private func handleLLMChanged(_ newLLM: LLMTarget) {
        llmBridgeForInput = createLLMBridge(for: newLLM)
    }
}


