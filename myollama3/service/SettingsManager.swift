//
//  SettingsManager.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import Foundation

// MARK: - LLMTarget Extensions
extension LLMTarget: Codable, CaseIterable {
    public static var allCases: [LLMTarget] {
        return [.ollama, .lmstudio, .claude, .openai]
    }
    
    // Manual Codable implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .ollama:
            try container.encode("ollama")
        case .lmstudio:
            try container.encode("lmstudio")
        case .claude:
            try container.encode("claude")
        case .openai:
            try container.encode("openai")
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "ollama":
            self = .ollama
        case "lmstudio":
            self = .lmstudio
        case "claude":
            self = .claude
        case "openai":
            self = .openai
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize LLMTarget from invalid String value \(rawValue)"
                )
            )
        }
    }
}

extension LLMTarget {
    var displayName: String {
        switch self {
        case .ollama:
            return "Ollama"
        case .lmstudio:
            return "LM Studio"
        case .claude:
            return "Claude"
        case .openai:
            return "OpenAI"
        }
    }
    
    var description: String {
        switch self {
        case .ollama:
            return "Local AI models"
        case .lmstudio:
            return "Local studio environment"
        case .claude:
            return "Anthropic's Claude AI"
        case .openai:
            return "OpenAI's GPT models"
        }
    }
}

class SettingsManager: ObservableObject {
    private let enabledLLMsKey = "enabled_llms"
    
    @Published var enabledLLMs: Set<LLMTarget> = []
    
    init() {
        loadEnabledLLMs()
    }
    
    private func loadEnabledLLMs() {
        if let data = UserDefaults.standard.data(forKey: enabledLLMsKey),
           let decoded = try? JSONDecoder().decode(Set<LLMTarget>.self, from: data) {
            enabledLLMs = decoded
        } else {
            // Default to Ollama only
            enabledLLMs = [.ollama]
            saveEnabledLLMs()
        }
    }
    
    private func saveEnabledLLMs() {
        if let encoded = try? JSONEncoder().encode(enabledLLMs) {
            UserDefaults.standard.set(encoded, forKey: enabledLLMsKey)
        }
    }
    
    func isLLMEnabled(_ llm: LLMTarget) -> Bool {
        return enabledLLMs.contains(llm)
    }
    
    func setLLMEnabled(_ llm: LLMTarget, enabled: Bool) {
        if enabled {
            enabledLLMs.insert(llm)
        } else {
            enabledLLMs.remove(llm)
        }
        saveEnabledLLMs()
    }
    
    func getEnabledLLMs() -> [(name: String, type: LLMTarget)] {
        return enabledLLMs.map { llm in
            (name: llm.displayName, type: llm)
        }
    }
}

