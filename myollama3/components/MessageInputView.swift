//
//  MessageInputView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct MessageInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var isLoading: Bool
    var shouldFocus: Bool
    var onSend: () -> Void
    @Binding var selectedImage: UIImage?
    var isInputFocused: FocusState<Bool>.Binding
    
    @State private var showImagePicker: Bool = false
    @State private var showImagePreview: Bool = false
    @State private var textHeight: CGFloat = 40
    
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
        
        let calculatedHeight = textSize.height + 24 // 여백 포함
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
            
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
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
                
                VStack(spacing: 8) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo")
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
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading 
                            ? Color.gray 
                            : Color.appPrimary
                        )
                    )
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal)
        }
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
                                Button("l_done".localized) {
                                    showImagePreview = false
                                }
                            }
                        }
                }
            }
        }
    }
}
