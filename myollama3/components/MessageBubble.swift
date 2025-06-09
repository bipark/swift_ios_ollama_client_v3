//
//  MessageBubble.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import MarkdownUI
import Toasts

struct MessageBubble: View {
    let message: Message
    let allMessages: [Message]
    let onDelete: () -> Void
    @State private var showShareSheet = false
    @State private var showImageActionSheet = false
    @State private var imageToShare: UIImage?
    @Environment(\.presentToast) private var presentToast
    
    private func formatQnA() -> String {
        guard let index = allMessages.firstIndex(where: { $0.id == message.id }) else {
            return message.content
        }
        
        if message.isUser {
            if index + 1 < allMessages.count && !allMessages[index + 1].isUser {
                var question = message.content
                if message.image != nil && question.isEmpty {
                    question = "l_message_image".localized
                } else if message.image != nil {
                    question = "\(question)\n\("l_message_image_attached".localized)"
                }
                let answer = allMessages[index + 1].content
                return String(format: "l_message_question_answer_format".localized, question, answer)
            }
        } else {
            if index > 0 && allMessages[index - 1].isUser {
                var question = allMessages[index - 1].content
                if allMessages[index - 1].image != nil && question.isEmpty {
                    question = "l_message_image".localized
                } else if allMessages[index - 1].image != nil {
                    question = "\(question)\n\("l_message_image_attached".localized)"
                }
                let answer = message.content
                return String(format: "l_message_question_answer_format".localized, question, answer)
            }
        }
        
        var content = message.content
        if message.image != nil && content.isEmpty {
            content = "l_message_image".localized
        } else if message.image != nil {
            content = "\(content)\n\("l_message_image_attached".localized)"
        }
        return content
    }
    
    private func showImageActions(image: UIImage) {
        imageToShare = image
        showImageActionSheet = true
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(12)
                            .onTapGesture {
                                showImageActions(image: image)
                            }
                    }
                    
                    if !message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(message.content)
                            .font(.system(size: 14))
                            .padding(12)
                            .background(Color.appUserMessage)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = message.content
                    }) {
                        Label("l_message_copy".localized, systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("l_message_share_qa".localized, systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("l_message_delete".localized, systemImage: "trash")
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [formatQnA()])
                }
                .actionSheet(isPresented: $showImageActionSheet) {
                    ActionSheet(
                        title: Text("l_message_image_options".localized),
                        message: Text("l_message_image_what_to_do".localized),
                        buttons: [
                            .default(Text("l_message_save".localized)) {
                                guard let image = imageToShare else { return }
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                presentToast(
                                    ToastValue(
                                        icon: Image(systemName: "info.circle"),
                                        message: "l_message_image_saved".localized
                                    )
                                )
                            },
                            .default(Text("l_message_share".localized)) {
                                if let image = imageToShare {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    let shareSheet = UIActivityViewController(
                                        activityItems: [image],
                                        applicationActivities: nil
                                    )
                                    
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootViewController = windowScene.windows.first?.rootViewController {
                                        rootViewController.present(shareSheet, animated: true)
                                    }
                                }
                            },
                            .cancel(Text("l_message_cancel".localized))
                        ]
                    )
                }
            } else {
                VStack {
                    Markdown(message.content)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = formatQnA()
                    }) {
                        Label("l_message_copy".localized, systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("l_message_share_qa".localized, systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("l_message_delete".localized, systemImage: "trash")
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [formatQnA()])
                }
                
                Spacer()
            }
        }
    }
}
