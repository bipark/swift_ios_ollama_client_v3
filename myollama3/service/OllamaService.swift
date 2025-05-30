//
//  OllamaService.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import Foundation
import Combine
import UIKit

@MainActor
class OllamaService: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id = UUID()
        var content: String
        let isUser: Bool
        let timestamp = Date()
        let image: UIImage?
        
        static func == (lhs: Message, rhs: Message) -> Bool {
            return lhs.id == rhs.id
        }
        
        init(content: String, isUser: Bool, image: UIImage? = nil) {
            self.content = content
            self.isUser = isUser
            self.image = image
        }
    }
    
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var currentResponse: String = ""
    
    private var baseURL: URL
    private var generationTask: Task<Void, Never>?
    private let defaultModel = "llama"
    private var tempResponse: String = ""
    
    private let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300.0
        configuration.timeoutIntervalForResource = 600.0
        return URLSession(configuration: configuration)
    }()
    
    private let databaseService = DatabaseService()
    private let conversationId: String
    private var instruction: String {
        UserDefaults.standard.string(forKey: "ollama_instruction") ?? "l_default_instruction".localized
    }
    private var temperature: Double {
        let temp = UserDefaults.standard.double(forKey: "ollama_temperature")
        return temp > 0 ? temp : 0.7
    }
    
    private var topP: Double {
        let value = UserDefaults.standard.double(forKey: "ollama_top_p")
        return value > 0 ? value : 0.9
    }
    
    private var topK: Int {
        let value = UserDefaults.standard.integer(forKey: "ollama_top_k")
        return value > 0 ? value : 40
    }
    
    // MARK: - Initialization
    
    init(baseURL: URL? = nil, conversationId: String? = nil) {
        let savedURLString = UserDefaults.standard.string(forKey: "ollama_base_url")
        let defaultBaseURL = URL(string: "http://192.168.0.1:11434")!
        
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else if let savedURLString = savedURLString, let savedURL = URL(string: savedURLString) {
            self.baseURL = savedURL
        } else {
            self.baseURL = defaultBaseURL
        }
        
        self.conversationId = conversationId ?? UUID().uuidString
        
        if let providedId = conversationId {
            Task {
                _ = await loadConversationHistory(groupId: providedId)
            }
        }
        
        setupUserDefaultsObserver()
    }
    
    private func setupUserDefaultsObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func userDefaultsDidChange() {
        if let savedURLString = UserDefaults.standard.string(forKey: "ollama_base_url"),
           let savedURL = URL(string: savedURLString) {
            self.baseURL = savedURL
        }
    }
    
    @MainActor
    func updateBaseURL(_ newURL: URL) {
        self.baseURL = newURL
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
    
    func sendMessage(content: String, image: UIImage? = nil, model: String? = nil) async throws -> Message {
        isLoading = true
        errorMessage = nil
        tempResponse = ""
        currentResponse = ""
        
        let userMessage = Message(content: content, isUser: true, image: image)
        messages.append(userMessage)
        
        generationTask?.cancel()
        
        var aiMessage: Message?
        let selectedModel = model ?? defaultModel
        
        let startTime = Date()
        
        generationTask = Task {
            defer { isLoading = false }
            
            do {
                var chatMessages: [[String: Any]] = [
                    ["role": "system", "content": instruction]
                ]
                
                for i in 0..<messages.count - 1 {
                    let message = messages[i]
                    let role = message.isUser ? "user" : "assistant"
                    chatMessages.append(["role": role, "content": message.content])
                }
                
                var currentUserMessage: [String: Any] = [
                    "role": "user",
                    "content": content
                ]
                
                if let userImage = image,
                   let imageBase64 = encodeImageToBase64(userImage) {
                    currentUserMessage["images"] = [imageBase64]
                }
                
                chatMessages.append(currentUserMessage)
                
                let requestURL = baseURL.appendingPathComponent("api/chat")
                var request = URLRequest(url: requestURL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 300.0
                
                let requestData: [String: Any] = [
                    "model": selectedModel,
                    "messages": chatMessages,
                    "stream": true,
                    "temperature": temperature,
                    "top_p": topP,
                    "top_k": topK
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
                
                try await self.processStream(request: request)
                
                if !tempResponse.isEmpty {
                    let endTime = Date()
                    let elapsedTime = endTime.timeIntervalSince(startTime)
                    
                    if !tempResponse.contains("**\(selectedModel)**") {
                        let estimatedTokens = Double(tempResponse.count) / 4.0
                        let tokensPerSecond = elapsedTime > 0 ? estimatedTokens / elapsedTime : 0
                        tempResponse += "\n\n\(selectedModel)  "
                        tempResponse += "\n\(String(format: "%.1f", tokensPerSecond)) tokens/sec  "
                        tempResponse += "\n\(String(format: "%.1f", elapsedTime)) sec"
                    }
                    
                    let message = Message(content: tempResponse, isUser: false, image: nil)
                    messages.append(message)
                    aiMessage = message
                    
                    try await self.saveConversationToDatabase(
                        question: content,
                        answer: tempResponse,
                        engine: selectedModel
                    )
                    
                    tempResponse = ""
                    currentResponse = ""
                }
                
            } catch {
                errorMessage = error.localizedDescription
                print("Error: \(error)")
                
                if !Task.isCancelled && !tempResponse.isEmpty {
                    let message = Message(content: tempResponse + "\n\("l_error_occurred".localized)", isUser: false, image: nil)
                    messages.append(message)
                    aiMessage = message
                    
                    try? await self.saveConversationToDatabase(
                        question: content,
                        answer: tempResponse + "\n\("l_error_occurred".localized)",
                        engine: selectedModel
                    )
                    
                    tempResponse = ""
                    currentResponse = ""
                }
            }
        }
        
        await generationTask?.value
        
        return aiMessage ?? Message(content: "l_response_generation_failed".localized, isUser: false, image: nil)
    }
    
    private func processStream(request: URLRequest) async throws {
        let (data, response) = try await urlSession.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        for try await line in data.lines {
            if Task.isCancelled { break }
            
            if line.isEmpty { continue }
            
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    tempResponse += content
                    currentResponse = tempResponse
                }
                
                if let done = json["done"] as? Bool, done {
                    break
                }
            }
        }
    }
    
    func cancelGeneration() {
        generationTask?.cancel()
        
        if !tempResponse.isEmpty {
            let message = Message(content: tempResponse + "\n\("l_user_cancelled".localized)", isUser: false, image: nil)
            messages.append(message)
            
            if let lastUserMessage = messages.last(where: { $0.isUser }) {
                Task {
                    try? await saveConversationToDatabase(
                        question: lastUserMessage.content,
                        answer: tempResponse + "\n\("l_user_cancelled".localized)",
                        engine: defaultModel
                    )
                }
            }
            
            tempResponse = ""
            currentResponse = ""
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        errorMessage = nil
        tempResponse = ""
        currentResponse = ""
    }
    
    func getAvailableModels() async throws -> [String] {
        do {
            let requestURL = baseURL.appendingPathComponent("api/tags")
            let (data, _) = try await urlSession.data(from: requestURL)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                return models.compactMap { $0["name"] as? String }
            }
            
            return [defaultModel]
            
        } catch {
            errorMessage = String(format: "l_models_error".localized, error.localizedDescription)
            print("Error: \(error)")
            throw error
        }
    }
    
    private func saveConversationToDatabase(question: String, answer: String, engine: String) async throws {
        var imageBase64: String? = nil
        if let lastUserMessage = messages.last(where: { $0.isUser }) {
            if let image = lastUserMessage.image {
                imageBase64 = encodeImageToBase64(image)
            }
        }
        
        try databaseService.saveQuestion(
            groupId: conversationId,
            instruction: nil,
            question: question,
            answer: answer,
            image: imageBase64,
            engine: engine,
            baseUrl: baseURL.absoluteString
        )
    }
    
    func loadConversationHistory(groupId: String) async -> String? {
        do {
            let conversations = try databaseService.getQuestionsForGroup(groupId: groupId)
            
            messages.removeAll()
            
            var lastUsedModel: String? = nil
            
            for conversation in conversations {
                var userImage: UIImage? = nil
                if let imageBase64 = conversation.image {
                    userImage = convertBase64ToImage(imageBase64)
                }
                
                let userMessage = Message(content: conversation.question, isUser: true, image: userImage)
                let aiMessage = Message(content: conversation.answer, isUser: false, image: nil)
                
                messages.append(userMessage)
                messages.append(aiMessage)
                
                if let engine = conversation.engine {
                    lastUsedModel = engine
                }
            }
            
            return lastUsedModel
        } catch {
            print(String(format: "l_conversation_history_error".localized, error.localizedDescription))
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
    
    func getConversationId() -> String {
        return conversationId
    }
    
    func getBaseURL() -> URL {
        return baseURL
    }
    
    func getAllConversations() async throws -> [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] {
        let groupsData = try databaseService.getAllGroups()
        var results: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for group in groupsData {
            if let date = dateFormatter.date(from: group.lastCreated) {
                var firstQuestion = "l_conversation".localized
                var firstAnswer = ""
                var engine: String? = nil
                var image: String? = nil
                
                do {
                    let conversations = try databaseService.getQuestionsForGroup(groupId: group.groupId)
                    if let first = conversations.first {
                        let question = first.question
                        if question.count > 30 {
                            firstQuestion = String(question.prefix(30)) + "..."
                        } else {
                            firstQuestion = question
                        }
                        
                        let answer = first.answer
                        if answer.count > 50 {
                            firstAnswer = String(answer.prefix(50)) + "..."
                        } else {
                            firstAnswer = answer
                        }
                        
                        engine = first.engine
                        image = first.image
                    }
                } catch {
                    print(String(format: "l_first_question_error".localized, error.localizedDescription))
                }
                
                results.append((id: group.groupId, date: date, baseUrl: group.baseUrl, firstQuestion: firstQuestion, firstAnswer: firstAnswer, engine: engine, image: image))
            }
        }
        
        return results
    }
    
    func deleteConversation(groupId: String) async throws {
        try databaseService.deleteGroup(groupId: groupId)
    }
    
    func deleteMessage(at index: Int) async throws {
        guard index < messages.count else { return }
        
        let messageToRemove = messages[index]
        let isUserMessage = messageToRemove.isUser
        
        var indicesToRemove: [Int] = []
        
        if isUserMessage && index + 1 < messages.count && !messages[index + 1].isUser {
            indicesToRemove = [index, index + 1]
        }
        else if !isUserMessage && index > 0 && messages[index - 1].isUser {
            indicesToRemove = [index - 1, index]
        }
        else {
            indicesToRemove = [index]
        }
        
        do {
            try await deleteMessagesFromDatabase(indices: indicesToRemove)
            
            for i in indicesToRemove.sorted(by: >) {
                messages.remove(at: i)
            }
        } catch {
            throw error
        }
    }
    
    private func deleteMessagesFromDatabase(indices: [Int]) async throws {
        let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
        
        guard let maxIndex = indices.max(), maxIndex < conversations.count * 2 else {
            throw NSError(domain: "OllamaService", code: 1, userInfo: [NSLocalizedDescriptionKey: "l_index_out_of_range".localized])
        }
        
        var createdTimesToDelete: [String] = []
        
        for index in indices {
            let dbIndex = index / 2
            
            if dbIndex < conversations.count && !createdTimesToDelete.contains(conversations[dbIndex].created) {
                createdTimesToDelete.append(conversations[dbIndex].created)
            }
        }
        
        for created in createdTimesToDelete {
            try databaseService.deleteQuestion(groupId: conversationId, created: created)
        }
    }
    
    func getLastUsedModel() async -> String? {
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
    
    func searchAllConversations(searchText: String) async throws -> [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] {
        let allConversations = try await getAllConversations()
        
        if searchText.isEmpty {
            return allConversations
        }
        
        var matchingConversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
        
        for conversation in allConversations {
            var isMatch = false
            
            if conversation.firstQuestion.localizedCaseInsensitiveContains(searchText) {
                isMatch = true
            }
            
            if conversation.firstAnswer.localizedCaseInsensitiveContains(searchText) {
                isMatch = true
            }
            
            if !isMatch {
                do {
                    let fullConversations = try databaseService.getQuestionsForGroup(groupId: conversation.id)
                    for fullConv in fullConversations {
                        if fullConv.question.localizedCaseInsensitiveContains(searchText) ||
                           fullConv.answer.localizedCaseInsensitiveContains(searchText) {
                            isMatch = true
                            break
                        }
                    }
                } catch {
                    continue
                }
            }
            
            if isMatch {
                matchingConversations.append(conversation)
            }
        }
        
        return matchingConversations
    }
} 
