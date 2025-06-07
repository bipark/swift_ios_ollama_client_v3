//
//  SettingsView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI

class SettingsManager: ObservableObject {
    @Published var baseURL: String
    @Published var lmStudioURL: String
    @Published var claudeAPIKey: String
    @Published var openAIAPIKey: String
    @Published var instruction: String
    @Published var temperature: Double
    @Published var topP: Double
    @Published var topK: Int
    @Published var isOllamaEnabled: Bool
    @Published var isLMStudioEnabled: Bool
    @Published var isClaudeEnabled: Bool
    @Published var isOpenAIEnabled: Bool
    
    private let baseURLKey = "ollama_base_url"
    private let lmStudioURLKey = "lmstudio_base_url"
    private let claudeAPIKeyKey = "claude_api_key"
    private let openAIAPIKeyKey = "openai_api_key"
    private let instructionKey = "ollama_instruction"
    private let temperatureKey = "ollama_temperature"
    private let topPKey = "ollama_top_p"
    private let topKKey = "ollama_top_k"
    private let isOllamaEnabledKey = "is_ollama_enabled"
    private let isLMStudioEnabledKey = "is_lmstudio_enabled"
    private let isClaudeEnabledKey = "is_claude_enabled"
    private let isOpenAIEnabledKey = "is_openai_enabled"
    
    init() {
        self.baseURL = UserDefaults.standard.string(forKey: baseURLKey) ?? "http://192.168.0.1:11434"
        self.lmStudioURL = UserDefaults.standard.string(forKey: lmStudioURLKey) ?? "http://192.168.0.6:1234"
        self.claudeAPIKey = UserDefaults.standard.string(forKey: claudeAPIKeyKey) ?? ""
        self.openAIAPIKey = UserDefaults.standard.string(forKey: openAIAPIKeyKey) ?? ""
        self.instruction = UserDefaults.standard.string(forKey: instructionKey) ?? "l_default_instruction".localized
        self.temperature = UserDefaults.standard.double(forKey: temperatureKey)
        self.topP = UserDefaults.standard.double(forKey: topPKey)
        self.topK = UserDefaults.standard.integer(forKey: topKKey)
        self.isOllamaEnabled = UserDefaults.standard.bool(forKey: isOllamaEnabledKey)
        self.isLMStudioEnabled = UserDefaults.standard.bool(forKey: isLMStudioEnabledKey)
        self.isClaudeEnabled = UserDefaults.standard.bool(forKey: isClaudeEnabledKey)
        self.isOpenAIEnabled = UserDefaults.standard.bool(forKey: isOpenAIEnabledKey)
        
        if self.temperature == 0 {
            self.temperature = 0.7
        }
        
        if self.topP == 0 {
            self.topP = 0.9
        }
        
        if self.topK == 0 {
            self.topK = 40
        }
        
        if !UserDefaults.standard.bool(forKey: "default_settings_initialized") {
            self.isOllamaEnabled = true
            UserDefaults.standard.set(true, forKey: "default_settings_initialized")
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
        UserDefaults.standard.set(lmStudioURL, forKey: lmStudioURLKey)
        UserDefaults.standard.set(claudeAPIKey, forKey: claudeAPIKeyKey)
        UserDefaults.standard.set(openAIAPIKey, forKey: openAIAPIKeyKey)
        UserDefaults.standard.set(instruction, forKey: instructionKey)
        UserDefaults.standard.set(temperature, forKey: temperatureKey)
        UserDefaults.standard.set(topP, forKey: topPKey)
        UserDefaults.standard.set(topK, forKey: topKKey)
        UserDefaults.standard.set(isOllamaEnabled, forKey: isOllamaEnabledKey)
        UserDefaults.standard.set(isLMStudioEnabled, forKey: isLMStudioEnabledKey)
        UserDefaults.standard.set(isClaudeEnabled, forKey: isClaudeEnabledKey)
        UserDefaults.standard.set(isOpenAIEnabled, forKey: isOpenAIEnabledKey)
    }
    
    func getEnabledLLMs() -> [(name: String, type: LLMTarget)] {
        var enabledLLMs: [(name: String, type: LLMTarget)] = []
        
        if isOllamaEnabled {
            enabledLLMs.append(("Ollama", .ollama))
        }
        if isLMStudioEnabled {
            enabledLLMs.append(("LMStudio", .lmstudio))
        }
        if isClaudeEnabled {
            enabledLLMs.append(("Claude", .claude))
        }
        if isOpenAIEnabled {
            enabledLLMs.append(("OpenAI", .openai))
        }
        
        return enabledLLMs
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager()
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCheckingConnection = false
    @State private var isCheckingLMStudioConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var lmStudioConnectionStatus: ConnectionStatus = .unknown
    @State private var isSaving = false
    @State private var showConfirmationAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingData = false
    
    @State private var appVersion = ""
    @State private var buildNumber = ""

    
    private let databaseService = DatabaseService()
    
    enum ConnectionStatus: Equatable {
        case unknown
        case success
        case failed(String)
        
        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown):
                return true
            case (.success, .success):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
        
        var message: String {
            switch self {
            case .unknown:
                return ""
            case .success:
                return "l_connected_to_server".localized
            case .failed(let error):
                return String(format: "l_connection_error".localized, error)
            }
        }
        
        var color: Color {
            switch self {
            case .unknown:
                return .clear
            case .success:
                return Color.appPrimary.opacity(0.7)
            case .failed:
                return .red
            }
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("LLM Servers")) {
                // Ollama Server
                Toggle(isOn: $settings.isOllamaEnabled) {
                    Text("Ollama Server")
                }
                if settings.isOllamaEnabled {
                    TextField("Base URL", text: $settings.baseURL)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Button(action: checkServerConnection) {
                        HStack {
                            Text("l_check_server_connection".localized)
                                .foregroundColor(AppColor.link)
                            Spacer()
                            if isCheckingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .disabled(isCheckingConnection)
                    
                    if connectionStatus != .unknown {
                        Text(connectionStatus.message)
                            .font(.footnote)
                            .foregroundColor(connectionStatus.color)
                            .padding(.top, 4)
                    }
                }

                // LMStudio Server
                Toggle(isOn: $settings.isLMStudioEnabled) {
                    Text("LMStudio")
                }
                TextField("Base URL", text: $settings.lmStudioURL)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    
                Button(action: checkLMStudioConnection) {
                    HStack {
                        Text("l_check_server_connection".localized)
                            .foregroundColor(AppColor.link)
                        Spacer()
                        if isCheckingLMStudioConnection {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isCheckingLMStudioConnection)
                
                if lmStudioConnectionStatus != .unknown {
                    Text(lmStudioConnectionStatus.message)
                        .font(.footnote)
                        .foregroundColor(lmStudioConnectionStatus.color)
                        .padding(.top, 4)
                }
            }

            // Claude API Section
            Section(header: Text("Claude API")) {
                Toggle(isOn: $settings.isClaudeEnabled) {
                    Text("Enable Claude")
                }
                TextField("API Key", text: $settings.claudeAPIKey)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)

            }

            // OpenAI API Section
            Section(header: Text("OpenAI API")) {
                Toggle(isOn: $settings.isOpenAIEnabled) {
                    Text("Enable OpenAI")
                }
                TextField("API Key", text: $settings.openAIAPIKey)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            }
            
            Section(header: Text("l_llm_instructions".localized), footer: Text("l_llm_instructions_desc".localized)) {
                TextEditor(text: $settings.instruction)
                    .frame(minHeight: 100)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("l_temperature".localized), footer: Text("l_temperature_desc".localized)) {
                HStack {
                    Text(String(format: "%.1f", settings.temperature))
                        .frame(width: 40)
                    Slider(value: $settings.temperature, in: 0.1...2.0, step: 0.1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section(header: Text("l_top_p".localized), footer: Text("l_top_p_desc".localized)) {
                HStack {
                    Text(String(format: "%.1f", settings.topP))
                        .frame(width: 40)
                    Slider(value: $settings.topP, in: 0.1...1.0, step: 0.1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section(header: Text("l_top_k".localized), footer: Text("l_top_k_desc".localized)) {
                HStack {
                    Text("\(settings.topK)")
                        .frame(width: 40)
                    Slider(value: Binding(
                        get: { Double(settings.topK) },
                        set: { settings.topK = Int($0) }
                    ), in: 1...100, step: 1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section (header: Text("l_reset".localized), footer: Text("l_reset_llm_desc".localized)) {
                Button("l_reset_llm_settings".localized) {
                    settings.baseURL = "http://192.168.0.1:11434"
                    settings.lmStudioURL = "http://192.168.0.6:1234"
                    settings.claudeAPIKey = ""
                    settings.openAIAPIKey = ""
                    settings.instruction = "l_default_instruction".localized
                    settings.temperature = 0.7
                    settings.topP = 0.9
                    settings.topK = 40
                    settings.isOllamaEnabled = true
                    settings.isLMStudioEnabled = false
                    settings.isClaudeEnabled = false
                    settings.isOpenAIEnabled = false
                }
                .foregroundColor(AppColor.link)
            }
            
            // 전체 데이터 삭제 섹션 추가
            Section(header: Text("l_delete".localized), footer: Text("l_delete_all_desc".localized) ) {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Text("l_delete_all_conversations".localized)
                            .foregroundColor(.red)
                        Spacer()
                        if isDeletingData {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isDeletingData)
            }
            
            //
            Section (header: Text("l_app_settings".localized)) {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }) {
                    HStack {
                        Text("l_app_settings".localized)
                            .foregroundColor(AppColor.link)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                Button(action: {
                    if let url = URL(string: "http://practical.kr/?p=828") {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }) {
                    HStack {
                        Text("l_ollama_server_config".localized)
                            .foregroundColor(AppColor.link)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }
            
            Section (header: Text("l_app_info".localized)){
                HStack {
                    Text("l_version".localized)
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Text("l_about_myollama".localized)
                            .foregroundColor(AppColor.link)
                    }
                }
            }

        }
        .navigationTitle("l_settings".localized)
        .onAppear {
            loadAppVersion()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("l_save".localized) {
                    saveSettings()
                }
                .foregroundColor(Color.appPrimary)
                .bold()
                .disabled(isSaving)
            }
        }
        .overlay {
            if isSaving {
                ProgressView("l_checking_server".localized)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("l_ok".localized, role: .cancel) {
                if alertMessage == "l_server_check_complete".localized {
                    dismiss()
                }
            }
        }
        .alert("l_server_connection_failed".localized, isPresented: $showConfirmationAlert) {
            Button("l_cancel".localized, role: .cancel) {}
            Button("l_save_anyway".localized, role: .destructive) {
                settings.saveSettings()
                
                NotificationCenter.default.post(
                    name: Notification.Name("OllamaServerURLChanged"),
                    object: nil,
                    userInfo: ["url": settings.baseURL]
                )
                
                dismiss()
            }
            .tint(Color.appPrimary)
        } message: {
            Text("l_connection_failed_prompt".localized)
        }
        .alert("l_delete_all_conversations_title".localized, isPresented: $showDeleteConfirmation) {
            Button("l_cancel".localized, role: .cancel) {}
            Button("l_delete_confirm".localized, role: .destructive) {
                deleteAllData()
            }
            .foregroundColor(.red)
        } message: {
            Text("l_delete_all_warning".localized)
        }
    }
    
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersion = version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.buildNumber = build
        }
    }
    
    private func saveSettings() {
        if let url = URL(string: settings.baseURL) {
            let oldURLString = UserDefaults.standard.string(forKey: "ollama_base_url")
            
            if oldURLString != settings.baseURL {
                isSaving = true
                
                let tempService = OllamaService(baseURL: url)
                
                Task {
                    do {
                        _ = try await tempService.getAvailableModels()
                        
                        await MainActor.run {
                            isSaving = false
                            
                            settings.saveSettings()
                            
                            NotificationCenter.default.post(
                                name: Notification.Name("OllamaServerURLChanged"),
                                object: nil,
                                userInfo: ["url": settings.baseURL]
                            )
                            
                            alertMessage = "l_server_check_complete".localized
                            showAlert = true
                        }
                    } catch {
                        await MainActor.run {
                            isSaving = false
                            
                            alertMessage = String(format: "l_connection_error".localized, error.localizedDescription)
                            
                            showConfirmationAlert = true
                        }
                    }
                }
            } else {
                settings.saveSettings()
                alertMessage = "l_server_check_complete".localized
                showAlert = true
            }
        } else {
            alertMessage = "l_url_format_invalid".localized
            showAlert = true
        }
    }
    
    private func checkServerConnection() {
        guard let url = URL(string: settings.baseURL) else {
            connectionStatus = .failed("l_connection_error".localized)
            return
        }
        
        isCheckingConnection = true
        connectionStatus = .unknown
        
        Task {
            do {
                let service = OllamaService(baseURL: url)
                
                let models = try await service.getAvailableModels()
                
                await MainActor.run {
                    isCheckingConnection = false
                    connectionStatus = .success
                }
            } catch {
                await MainActor.run {
                    isCheckingConnection = false
                    connectionStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    private func checkLMStudioConnection() {
        guard let url = URL(string: settings.lmStudioURL) else {
            lmStudioConnectionStatus = .failed("l_connection_error".localized)
            return
        }
        
        isCheckingLMStudioConnection = true
        lmStudioConnectionStatus = .unknown
        
        Task {
            do {
                let service = OllamaService(baseURL: url)
                
                let models = try await service.getAvailableModels()
                
                await MainActor.run {
                    isCheckingLMStudioConnection = false
                    lmStudioConnectionStatus = .success
                }
            } catch {
                await MainActor.run {
                    isCheckingLMStudioConnection = false
                    lmStudioConnectionStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    private func deleteAllData() {
        isDeletingData = true
        
        Task {
            do {
                try databaseService.deleteAllData()
                
                await MainActor.run {
                    isDeletingData = false
                    alertMessage = "l_all_data_deleted".localized
                    showAlert = true
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("ConversationDataChanged"),
                        object: nil
                    )
                }
            } catch {
                await MainActor.run {
                    isDeletingData = false
                    alertMessage = String(format: "l_data_deletion_failed".localized, error.localizedDescription)
                    showAlert = true
                }
            }
        }
    }
}
