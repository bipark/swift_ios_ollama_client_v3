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
    // MARK: - Properties
    
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
    
    // MARK: - Private Properties
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
    
    // MARK: - Public Methods
    
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
                
                // API 요청 구성
                let requestURL = baseURL.appendingPathComponent("api/chat")
                var request = URLRequest(url: requestURL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 300.0 // 5분 타임아웃 설정
                
                // 요청 데이터 생성
                let requestData: [String: Any] = [
                    "model": selectedModel,
                    "messages": chatMessages,
                    "stream": true,
                    "temperature": temperature,
                    "top_p": topP,
                    "top_k": topK
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
                
                // 스트림 처리
                try await self.processStream(request: request)
                
                // 응답이 완료된 경우 메시지에 추가
                if !tempResponse.isEmpty {
                    // 응답 생성 완료 시간 기록
                    let endTime = Date()
                    let elapsedTime = endTime.timeIntervalSince(startTime)
                    
                    // API 응답에 이미 모델 정보가 포함되어 있으므로 추가 통계 제거
                    // 응답 끝에 모델 정보가 포함되어 있는지 확인
                    if !tempResponse.contains("**\(selectedModel)**") {
                        // 모델 정보가 없는 경우에만 추가
                        let estimatedTokens = Double(tempResponse.count) / 4.0
                        let tokensPerSecond = elapsedTime > 0 ? estimatedTokens / elapsedTime : 0
                        tempResponse += "\n\n\(selectedModel)  "
                        tempResponse += "\n\(String(format: "%.1f", tokensPerSecond)) tokens/sec  "
                        tempResponse += "\n\(String(format: "%.1f", elapsedTime)) sec"
                    }
                    
                    let message = Message(content: tempResponse, isUser: false, image: nil)
                    messages.append(message)
                    aiMessage = message
                    
                    // 데이터베이스에 대화 저장 
                    // (이미지도 Base64로 저장하려면 saveConversationToDatabase 함수 수정 필요)
                    try await self.saveConversationToDatabase(
                        question: content,
                        answer: tempResponse,
                        engine: selectedModel
                    )
                    
                    tempResponse = ""
                    currentResponse = "" // 현재 응답 초기화
                }
                
            } catch {
                errorMessage = error.localizedDescription
                print("Error: \(error)")
                
                // 취소되지 않은 오류인 경우 불완전한 응답 추가
                if !Task.isCancelled && !tempResponse.isEmpty {
                    let message = Message(content: tempResponse + "\n\("l_error_occurred".localized)", isUser: false, image: nil)
                    messages.append(message)
                    aiMessage = message
                    
                    // 오류가 있더라도 데이터베이스에 저장
                    try? await self.saveConversationToDatabase(
                        question: content,
                        answer: tempResponse + "\n\("l_error_occurred".localized)",
                        engine: selectedModel
                    )
                    
                    tempResponse = ""
                    currentResponse = "" // 현재 응답 초기화
                }
            }
        }
        
        // 생성 작업이 완료될 때까지 대기
        await generationTask?.value
        
        return aiMessage ?? Message(content: "l_response_generation_failed".localized, isUser: false, image: nil)
    }
    
    // 스트림 데이터 처리
    private func processStream(request: URLRequest) async throws {
        let (data, response) = try await urlSession.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // 바이트 스트림을 라인별로 처리
        for try await line in data.lines {
            if Task.isCancelled { break }
            
            // 빈 라인 무시
            if line.isEmpty { continue }
            
            // JSON 파싱 시도
            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let message = json["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    tempResponse += content
                    currentResponse = tempResponse // 현재 응답 업데이트
                }
                
                if let done = json["done"] as? Bool, done {
                    break
                }
            }
        }
    }
    
    /// 메시지 생성 취소
    func cancelGeneration() {
        generationTask?.cancel()
        
        // 취소된 경우 현재까지의 응답 추가
        if !tempResponse.isEmpty {
            let message = Message(content: tempResponse + "\n\("l_user_cancelled".localized)", isUser: false, image: nil)
            messages.append(message)
            
            // 취소된 응답도 데이터베이스에 저장
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
            currentResponse = "" // 현재 응답 초기화
        }
    }
    
    /// 모든 메시지 지우기
    func clearMessages() {
        messages.removeAll()
        errorMessage = nil
        tempResponse = ""
        currentResponse = "" // 현재 응답 초기화
    }
    
    /// 사용 가능한 모델 목록 가져오기 - 간단 구현
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
    
    // MARK: - Database Operations
    
    /// 대화 내용을 데이터베이스에 저장
    private func saveConversationToDatabase(question: String, answer: String, engine: String) async throws {
        // 마지막 사용자 메시지에서 이미지 가져오기
        var imageBase64: String? = nil
        if let lastUserMessage = messages.last(where: { $0.isUser }) {
            if let image = lastUserMessage.image {
                // 이미지를 Base64로 변환
                imageBase64 = encodeImageToBase64(image)
            }
        }
        
        try databaseService.saveQuestion(
            groupId: conversationId,
            instruction: nil,  // 현재 시스템 지시사항은 따로 저장하지 않음
            question: question,
            answer: answer,
            image: imageBase64,  // 이미지 Base64 문자열 저장
            engine: engine,
            baseUrl: baseURL.absoluteString  // URL 정보 저장
        )
    }
    
    /// 데이터베이스에서 대화 내역 로드
    func loadConversationHistory(groupId: String) async -> String? {
        do {
            let conversations = try databaseService.getQuestionsForGroup(groupId: groupId)
            
            // 기존 메시지 초기화
            messages.removeAll()
            
            // 마지막으로 사용한 모델 (가장 최근 대화의 모델)
            var lastUsedModel: String? = nil
            
            // 데이터베이스에서 가져온 대화 내역 추가
            for conversation in conversations {
                // 이미지 데이터가 있으면 UIImage로 변환
                var userImage: UIImage? = nil
                if let imageBase64 = conversation.image {
                    userImage = convertBase64ToImage(imageBase64)
                }
                
                let userMessage = Message(content: conversation.question, isUser: true, image: userImage)
                let aiMessage = Message(content: conversation.answer, isUser: false, image: nil)
                
                messages.append(userMessage)
                messages.append(aiMessage)
                
                // 모델 정보가 있으면 저장 (가장 마지막 대화의 모델이 선택됨)
                if let engine = conversation.engine {
                    lastUsedModel = engine
                }
            }
            
            return lastUsedModel
        } catch {
            print(String(format: "l_conversation_history_error".localized, error.localizedDescription))
            // 오류가 발생해도 앱은 계속 동작하도록 함
            return nil
        }
    }
    
    /// Base64 문자열을 UIImage로 변환
    private func convertBase64ToImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            print("l_base64_decoding_failed".localized)
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    /// 현재 대화 ID 반환
    func getConversationId() -> String {
        return conversationId
    }
    
    /// 현재 서버 URL 반환
    func getBaseURL() -> URL {
        return baseURL
    }
    
    /// 모든 대화 그룹 목록 가져오기
    func getAllConversations() async throws -> [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] {
        let groupsData = try databaseService.getAllGroups()
        var results: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for group in groupsData {
            if let date = dateFormatter.date(from: group.lastCreated) {
                // 각 그룹의 첫 번째 질문과 응답 가져오기
                var firstQuestion = "l_conversation".localized
                var firstAnswer = ""
                var engine: String? = nil
                var image: String? = nil
                
                do {
                    let conversations = try databaseService.getQuestionsForGroup(groupId: group.groupId)
                    if let first = conversations.first {
                        // 질문 텍스트를 적절한 길이로 자르기
                        let question = first.question
                        if question.count > 30 {
                            firstQuestion = String(question.prefix(30)) + "..."
                        } else {
                            firstQuestion = question
                        }
                        
                        // 응답 텍스트를 적절한 길이로 자르기
                        let answer = first.answer
                        if answer.count > 50 {
                            firstAnswer = String(answer.prefix(50)) + "..."
                        } else {
                            firstAnswer = answer
                        }
                        
                        // 모델 정보 저장
                        engine = first.engine
                        
                        // 이미지 정보 저장
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
    
    /// 대화 삭제
    func deleteConversation(groupId: String) async throws {
        try databaseService.deleteGroup(groupId: groupId)
    }
    
    /// 특정 메시지 및 관련 대화 쌍 삭제
    func deleteMessage(at index: Int) async throws {
        guard index < messages.count else { return }
        
        // 대화 쌍을 파악하기 위한 변수들
        let messageToRemove = messages[index]
        let isUserMessage = messageToRemove.isUser
        
        // 삭제할 대화 쌍의 인덱스 결정
        var indicesToRemove: [Int] = []
        
        // 사용자 메시지인 경우: 해당 메시지와 그 다음 AI 응답을 함께 처리
        if isUserMessage && index + 1 < messages.count && !messages[index + 1].isUser {
            indicesToRemove = [index, index + 1]
        }
        // AI 응답인 경우: 해당 응답과 그 직전 사용자 메시지를 함께 처리
        else if !isUserMessage && index > 0 && messages[index - 1].isUser {
            indicesToRemove = [index - 1, index]
        }
        // 그 외 경우(단독 메시지): 해당 메시지만 처리
        else {
            indicesToRemove = [index]
        }
        
        // 데이터베이스에서 대화 삭제
        do {
            try await deleteMessagesFromDatabase(indices: indicesToRemove)
            
            // UI에서 메시지 삭제 (역순으로 삭제해야 인덱스가 꼬이지 않음)
            for i in indicesToRemove.sorted(by: >) {
                messages.remove(at: i)
            }
        } catch {
            throw error
        }
    }
    
    /// 데이터베이스에서 메시지 삭제 (내부 구현)
    private func deleteMessagesFromDatabase(indices: [Int]) async throws {
        // 현재 대화 내역을 데이터베이스에서 로드
        let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
        
        // 인덱스가 범위 내에 있는지 확인
        guard let maxIndex = indices.max(), maxIndex < conversations.count * 2 else {
            throw NSError(domain: "OllamaService", code: 1, userInfo: [NSLocalizedDescriptionKey: "l_index_out_of_range".localized])
        }
        
        // 삭제할 데이터베이스 레코드 결정
        var createdTimesToDelete: [String] = []
        
        for index in indices {
            // 메시지 인덱스를 데이터베이스 인덱스로 변환
            // 대화 쌍은 두 개의 메시지(사용자+AI)를 포함하므로, 2로 나눈 몫이 대화 인덱스
            let dbIndex = index / 2
            
            // 해당 대화 쌍의 created 시간을 찾아 삭제 목록에 추가
            if dbIndex < conversations.count && !createdTimesToDelete.contains(conversations[dbIndex].created) {
                createdTimesToDelete.append(conversations[dbIndex].created)
            }
        }
        
        // 데이터베이스에서 실제 삭제 수행
        for created in createdTimesToDelete {
            try databaseService.deleteQuestion(groupId: conversationId, created: created)
        }
    }
    
    /// 마지막으로 사용한 모델 정보 가져오기
    func getLastUsedModel() async -> String? {
        guard !conversationId.isEmpty else { return nil }
        
        do {
            let conversations = try databaseService.getQuestionsForGroup(groupId: conversationId)
            
            // 가장 마지막 대화의 모델 정보 반환
            if let lastConversation = conversations.last {
                return lastConversation.engine
            }
            
            return nil
        } catch {
            print(String(format: "l_last_model_error".localized, error.localizedDescription))
            return nil
        }
    }
    
    /// 전체 대화 내용을 검색하는 메소드
    func searchAllConversations(searchText: String) async throws -> [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] {
        let allConversations = try await getAllConversations()
        
        if searchText.isEmpty {
            return allConversations
        }
        
        var matchingConversations: [(id: String, date: Date, baseUrl: String?, firstQuestion: String, firstAnswer: String, engine: String?, image: String?)] = []
        
        for conversation in allConversations {
            var isMatch = false
            
            // 제목에서 검색
            if conversation.firstQuestion.localizedCaseInsensitiveContains(searchText) {
                isMatch = true
            }
            
            // 첫 번째 응답에서 검색
            if conversation.firstAnswer.localizedCaseInsensitiveContains(searchText) {
                isMatch = true
            }
            
            // 전체 대화 내용에서 검색 (더 자세한 검색)
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
                    // 개별 대화 검색 실패는 무시하고 계속 진행
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
