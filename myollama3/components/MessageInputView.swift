//
//  MessageInputView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct MessageInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var isLoading: Bool
    var shouldFocus: Bool
    var onSend: () -> Void
    @Binding var selectedImage: UIImage?
    @Binding var selectedPDFText: String?
    @Binding var selectedTXTText: String?
    var isInputFocused: FocusState<Bool>.Binding
    @Binding var selectedLLM: LLMTarget
    @Binding var selectedModel: String
    var enabledLLMs: [(name: String, type: LLMTarget)]
    var llmBridge: LLMBridge
    @EnvironmentObject var settings: SettingsManager
    var onLLMChanged: ((LLMTarget) -> Void)?
    
    @State private var showImagePicker: Bool = false
    @State private var showImagePreview: Bool = false
    @State private var showAttachmentMenu: Bool = false
    @State private var showCamera: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var textHeight: CGFloat = 40
    @State private var availableModels: [String] = []
    @State private var isLoadingModels: Bool = false
    
    private func calculateTextHeight() -> CGFloat {
        let minHeight: CGFloat = 32
        let maxHeight: CGFloat = 60
        
        guard !text.isEmpty else { return minHeight }
        
        let availableWidth = UIScreen.main.bounds.width - 100
        let font = UIFont.systemFont(ofSize: 16)
        
        let textSize = text.boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let calculatedHeight = textSize.height + 16
        return min(max(calculatedHeight, minHeight), maxHeight)
    }
        
    var body: some View {
        VStack(spacing: 0) {
            // LLM and Model selection (more compact version)
            HStack(spacing: 8) {
                // LLM Selection
                Menu {
                    ForEach(enabledLLMs, id: \.type) { llm in
                        Button(action: {
                            selectedLLM = llm.type
                            loadModels()
                        }) {
                            HStack {
                                Text(llm.name)
                                if selectedLLM == llm.type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(enabledLLMs.first(where: { $0.type == selectedLLM })?.name ?? "LLM")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13))
                    }
                    .frame(width: 100, height: 30)
                    .foregroundColor(Color.appIcon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                // Model Selection
                Menu {
                    if isLoadingModels {
                        Text("Loading...")
                    } else {
                        ForEach(availableModels, id: \.self) { model in
                            Button(action: {
                                selectedModel = model
                            }) {
                                HStack {
                                    Text(model)
                                    if selectedModel == model {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if isLoadingModels {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Text(selectedModel.isEmpty ? "Model" : selectedModel)
                                .font(.system(size: 13))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13))
                        }
                    }
                    .frame(width: 170, height: 30)
                    .foregroundColor(Color.appIcon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            // Attachment preview section
            if selectedImage != nil || selectedPDFText != nil || selectedTXTText != nil {
                attachmentPreviewSection
                    .padding(.vertical, 4)
            }
            
            

            // Main input area
            HStack(alignment: .bottom, spacing: 8) {
                TextField("메시지를 입력하세요...", text: $text, axis: .vertical)
                    .font(.system(size: 14))
                    .focused($isFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading {
                            onSend()
                        }
                    }
                
                VStack(spacing: 6) {
                    Button(action: {
                        showAttachmentMenu = true
                    }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18))
                            .foregroundColor(Color.appIcon)
                    }
                    
                    Button(action: onSend) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil && selectedPDFText == nil && selectedTXTText == nil || isLoading
                            ? Color.gray
                            : Color.appPrimary
                        )
                    )
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil && selectedPDFText == nil && selectedTXTText == nil || isLoading)
                }
                .padding(.bottom, 2)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 6)
        .onAppear {
            textHeight = calculateTextHeight()
            
            // Load last used LLM and model
            loadLastUsedLLM()
            loadLastUsedModel()
            
            if shouldFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
        .onChange(of: isFocused) { newValue in
            isInputFocused.wrappedValue = newValue
        }
        .onChange(of: isInputFocused.wrappedValue) { newValue in
            isFocused = newValue
        }
        .onChange(of: selectedModel) { newModel in
            if !newModel.isEmpty {
                saveLastUsedModel(newModel)
            }
        }
        .onChange(of: selectedLLM) { newLLM in
            saveLastUsedLLM(newLLM)
            onLLMChanged?(newLLM)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedImage: $selectedImage, selectedPDFText: $selectedPDFText, selectedTXTText: $selectedTXTText)
        }
        .actionSheet(isPresented: $showAttachmentMenu) {
            ActionSheet(
                title: Text("l_attachment_options".localized),
                message: Text("l_attachment_how".localized),
                buttons: [
                    .default(Text("l_photo_library".localized)) {
                        showImagePicker = true
                    },
                    .default(Text("l_take_photo".localized)) {
                        showCamera = true
                    },
                    .default(Text("l_choose_files".localized)) {
                        showDocumentPicker = true
                    },
                    .cancel(Text("l_cancel".localized))
                ]
            )
        }
        .sheet(isPresented: $showImagePreview) {
            if let image = selectedImage {
                NavigationView {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle("Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showImagePreview = false
                                }
                            }
                        }
                }
            }
        }
        .task(id: selectedLLM) {
            loadModels()
        }
        .onChange(of: settings.enabledLLMs.count) { _ in
            loadModels()
        }
        .onReceive(settings.$enabledLLMs) { _ in
            loadModels()
        }
    }
    
    private func loadModels() {
        isLoadingModels = true
        availableModels = []
        
        Task {
            do {
                // Create a new LLMBridge instance for the selected LLM
                let tempBridge = createLLMBridge(for: selectedLLM)
                let models = await tempBridge.getAvailableModels()
                
                await MainActor.run {
                    self.availableModels = models
                    self.isLoadingModels = false
                    
                    // Select last used model if available
                    if !models.isEmpty {
                        let lastUsedModel = getLastUsedModel()
                        if !lastUsedModel.isEmpty && models.contains(lastUsedModel) {
                            selectedModel = lastUsedModel
                        } else if selectedModel.isEmpty || !models.contains(selectedModel) {
                            selectedModel = models.first ?? ""
                        }
                    }
                }
            } catch {
                print("Failed to load models: \(error)")
                await MainActor.run {
                    self.availableModels = []
                    self.isLoadingModels = false
                }
            }
        }
    }
    
    private func createLLMBridge(for target: LLMTarget) -> LLMBridge {
        return LLMBridge()
    }
    
    private func getLastUsedModelKey() -> String {
        switch selectedLLM {
        case .ollama:
            return "last_used_model_ollama"
        case .lmstudio:
            return "last_used_model_lmstudio"
        case .claude:
            return "last_used_model_claude"
        case .openai:
            return "last_used_model_openai"
        }
    }
    
    private func loadLastUsedModel() {
        let lastModel = getLastUsedModel()
        if !lastModel.isEmpty {
            selectedModel = lastModel
        }
    }
    
    private func getLastUsedModel() -> String {
        return UserDefaults.standard.string(forKey: getLastUsedModelKey()) ?? ""
    }
    
    private func saveLastUsedModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: getLastUsedModelKey())
    }
    
    private func loadLastUsedLLM() {
        let lastLLMString = UserDefaults.standard.string(forKey: "last_used_llm") ?? "ollama"
        if let lastLLM = getLLMFromString(lastLLMString) {
            selectedLLM = lastLLM
        }
    }
    
    private func saveLastUsedLLM(_ llm: LLMTarget) {
        let llmString = getLLMString(from: llm)
        UserDefaults.standard.set(llmString, forKey: "last_used_llm")
    }
    
    private func getLLMString(from llm: LLMTarget) -> String {
        switch llm {
        case .ollama:
            return "ollama"
        case .lmstudio:
            return "lmstudio"
        case .claude:
            return "claude"
        case .openai:
            return "openai"
        }
    }
    
    private func getLLMFromString(_ string: String) -> LLMTarget? {
        switch string {
        case "ollama":
            return .ollama
        case "lmstudio":
            return .lmstudio
        case "claude":
            return .claude
        case "openai":
            return .openai
        default:
            return nil
        }
    }
    
    @ViewBuilder
    private var attachmentPreviewSection: some View {
        VStack(spacing: 8) {
            if let image = selectedImage {
                attachmentRow(
                    icon: Image(uiImage: image).resizable().scaledToFit(),
                    title: "l_image_attached".localized,
                    subtitle: "\(Int(image.size.width)) × \(Int(image.size.height))",
                    onRemove: { selectedImage = nil }
                )
            }
            
            if let pdfText = selectedPDFText {
                attachmentRow(
                    icon: Image(systemName: "doc.fill").foregroundColor(.red),
                    title: "l_pdf_attached".localized,
                    subtitle: "\(pdfText.count) characters",
                    onRemove: { selectedPDFText = nil }
                )
            }
            
            if let txtText = selectedTXTText {
                attachmentRow(
                    icon: Image(systemName: "doc.plaintext.fill").foregroundColor(.blue),
                    title: "l_text_file_attached".localized,
                    subtitle: "\(txtText.count) characters",
                    onRemove: { selectedTXTText = nil }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func attachmentRow<Icon: View>(
        icon: Icon,
        title: String,
        subtitle: String,
        onRemove: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            icon
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
} 
