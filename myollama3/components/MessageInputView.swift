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
    var enabledLLMs: [(name: String, type: LLMTarget)]
    
    @State private var showImagePicker: Bool = false
    @State private var showImagePreview: Bool = false
    @State private var showAttachmentMenu: Bool = false
    @State private var showCamera: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var textHeight: CGFloat = 40
    @State private var showLLMMenu: Bool = false
    
    private func calculateTextHeight() -> CGFloat {
        let minHeight: CGFloat = 40
        let maxHeight: CGFloat = 120
        
        guard !text.isEmpty else { return minHeight }
        
        let availableWidth = UIScreen.main.bounds.width - 80
        let font = UIFont.systemFont(ofSize: 16)
        
        let textSize = text.boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let calculatedHeight = textSize.height + 24
        return min(max(calculatedHeight, minHeight), maxHeight)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let selectedImage = selectedImage {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()
                            .onTapGesture {
                                showImagePreview = true
                            }
                        
                        Button(action: {
                            self.selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            if let selectedPDFText = selectedPDFText {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PDF 문서")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("\(selectedPDFText.count) 글자")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button(action: {
                            self.selectedPDFText = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            if let selectedTXTText = selectedTXTText {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.plaintext.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("텍스트 파일")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("\(selectedTXTText.count) 글자")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button(action: {
                            self.selectedTXTText = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            VStack {
                Menu {
                    ForEach(enabledLLMs, id: \.type) { llm in
                        Button(action: {
                            selectedLLM = llm.type
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
                        Text(enabledLLMs.first(where: { $0.type == selectedLLM })?.name ?? "Select LLM")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color.appIcon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                HStack {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                            .frame(height: textHeight)
                        
                        VStack(spacing: 0) {
                            TextEditor(text: $text)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                                .frame(height: textHeight)
                                .onChange(of: text) { _ in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        textHeight = calculateTextHeight()
                                    }
                                }
                        }
                        
                        if text.isEmpty {
                            Text("l_message_input_placeholder".localized)
                                .font(.system(size: 16))
                                .foregroundColor(Color(.placeholderText))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    Button(action: {
                        showAttachmentMenu = true
                    }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 20))
                            .foregroundColor(Color.appIcon)
                    }
                    Button(action: onSend) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil && selectedPDFText == nil && selectedTXTText == nil || isLoading
                            ? Color.gray
                            : Color.appPrimary
                        )
                    )
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil && selectedPDFText == nil && selectedTXTText == nil || isLoading)
                }
            }
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
    }
}
