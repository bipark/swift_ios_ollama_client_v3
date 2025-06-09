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


typealias Message = OllamaService.Message

struct ChatView: View {
    @StateObject private var ollamaService: OllamaService
    
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
    private var llmBridge: LLMBridge

    
    private let selectedModelKey = "selected_model"
    private let defaultModel = "llama"
    
    init(conversationId: String? = nil, baseUrl: URL? = nil) {
        let defaultURLString = UserDefaults.standard.string(forKey: "ollama_base_url") ?? "http://192.168.0.1:11434"
        let url = baseUrl ?? URL(string: defaultURLString)!
        
        let baseURLString = url.scheme! + "://" + (url.host ?? "localhost")
        let port = url.port ?? 11434
        
        _ollamaService = StateObject(wrappedValue: OllamaService(baseURL: url, conversationId: conversationId))
        self.llmBridge = LLMBridge(baseURL: baseURLString, port: port)
        
        _isNewConversation = State(initialValue: conversationId == nil)
        
        if let modelName = UserDefaults.standard.string(forKey: selectedModelKey) {
            _selectedModel = State(initialValue: modelName)
        } else {
            _selectedModel = State(initialValue: defaultModel)
        }
    }
    
        var body: some View {
        VStack(spacing: 0) {
            if isModelLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                    Text("l_loading_models".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .dismissKeyboardOnTap(focusState: $isInputFocused)
                Spacer()
            } else if isModelLoadingFailed {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding(.bottom, 4)
                    
                    Text("l_models_load_failed".localized)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("l_check_server_and_retry".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("l_retry".localized) {
                        isModelLoading = true
                        isModelLoadingFailed = false
                        loadAvailableModels()
                    }
                    .padding(.top, 8)
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding()
                .dismissKeyboardOnTap(focusState: $isInputFocused)
            } else {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(ollamaService.messages) { message in
                                MessageBubble(
                                    message: message,
                                    allMessages: ollamaService.messages,
                                    onDelete: {
                                        messageToDelete = message.id
                                        showDeleteConfirmation = true
                                    }
                                )
                                .dismissKeyboardOnTap(focusState: $isInputFocused)
                            }
                            
                            if !ollamaService.currentResponse.isEmpty {
                                HStack {
                                    Markdown(ollamaService.currentResponse)
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
                            
                            if ollamaService.isLoading && ollamaService.currentResponse.isEmpty {
                                HStack {
                                    Text("l_thinking".localized)
                                        .padding(12)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    
                                    Spacer()
                                    
                                    Button {
                                        ollamaService.cancelGeneration()
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
                            
                            if let error = ollamaService.errorMessage {
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
                        .onChange(of: ollamaService.messages.count) { _ in
                            if let lastMessage = ollamaService.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: ollamaService.currentResponse) { _ in
                            if !ollamaService.currentResponse.isEmpty {
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
                                    isLoading: ollamaService.isLoading,
                                    shouldFocus: isNewConversation,
                                    onSend: sendMessage,
                                    selectedImage: $selectedImage,
                                    selectedPDFText: $selectedPDFText,
                                    selectedTXTText: $selectedTXTText,
                                    isInputFocused: $isInputFocused,
                                    selectedLLM: $selectedLLM,
                                    selectedModel: $selectedModel,
                                    enabledLLMs: settings.getEnabledLLMs(),
                                    llmBridge: llmBridge
                                )
                                .background(Color(.systemBackground))
                            }
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
                                if !ollamaService.messages.isEmpty && oldModel != model {
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
                    if !ollamaService.messages.isEmpty {
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
                async let modelsTask = ollamaService.getAvailableModels()
                async let lastModelTask = ollamaService.getLastUsedModel()
                
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
                    _ = try await ollamaService.sendMessage(
                        content: finalMessage, 
                        image: imageToSend, 
                        model: selectedModel
                    )
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteMessage(id: UUID) {
        guard let index = ollamaService.messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        Task {
            do {
                try await ollamaService.deleteMessage(at: index)
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
                ollamaService.updateBaseURL(url)
                
                isModelLoading = true
                isModelLoadingFailed = false
                loadAvailableModels()
            }
        }
    }
    
    private func formatAllMessages() -> String {
        var formattedText = "# \(selectedModel) \("l_conversation".localized)\n\n"
        
        if ollamaService.messages.isEmpty {
            return "l_no_conversations".localized
        }
        
        for (index, message) in ollamaService.messages.enumerated() {
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
                
                if index < ollamaService.messages.count - 1 {
                    formattedText += "---\n\n"
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date())
        
        formattedText += "\n\n\(String(format: "l_generated_time".localized, dateString))\n"
        formattedText += "\(String(format: "l_model".localized, selectedModel))\n"
        formattedText += "\(String(format: "l_server".localized, ollamaService.getBaseURL().absoluteString))"
        
        return formattedText
    }
    

}


