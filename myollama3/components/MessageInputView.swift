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
            // Attachment preview section
            if selectedImage != nil || selectedPDFText != nil || selectedTXTText != nil {
                attachmentPreviewSection
            }
            
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
            
            // Main input area
            HStack(alignment: .bottom, spacing: 8) {
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .focused($isFocused)
                    .frame(minHeight: textHeight, maxHeight: 60)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading {
                            onSend()
                        }
                    }
                    .onChange(of: text) { _ in
                        textHeight = calculateTextHeight()
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
    }
    
    private func loadModels() {
        isLoadingModels = true
        selectedModel = ""
        availableModels = []
        
        Task {
            do {
                let models = try await llmBridge.getAvailableModels()
                await MainActor.run {
                    self.availableModels = models
                    self.isLoadingModels = false
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
