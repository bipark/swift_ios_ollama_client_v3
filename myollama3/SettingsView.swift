//
//  SettingsView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import Toasts

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentToast) var presentToast
    @StateObject private var settings = SettingsManager()
    
    @State private var showAlert = false
    @State private var isCheckingConnection = false
    @State private var isCheckingLMStudioConnection = false
    @State private var isSaving = false
    @State private var showConfirmationAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingData = false
    
    @State private var appVersion = ""
    @State private var buildNumber = ""

    private let databaseService = DatabaseService()
    
    private func showToast(_ message: String) {
        presentToast(
            ToastValue(
                icon: Image(systemName: "info.circle"), message: message
            )
        )
    }
    
    var body: some View {
        Form {
            Section(header: Text("LLM Servers")) {
                // Ollama Server
                Toggle(isOn: Binding(
                    get: { settings.isLLMEnabled(.ollama) },
                    set: { settings.setLLMEnabled(.ollama, enabled: $0) }
                )) {
                    Text("Ollama Server")
                }
                if settings.isLLMEnabled(.ollama) {
                    TextField("Base URL", text: Binding(
                        get: { UserDefaults.standard.string(forKey: "ollama_base_url") ?? "http://192.168.0.1:11434" },
                        set: { UserDefaults.standard.set($0, forKey: "ollama_base_url") }
                    ))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .background(content: { RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)) })

                    Button(action: checkOllamaConnection) {
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
                }

                // LMStudio Server
                Toggle(isOn: Binding(
                    get: { settings.isLLMEnabled(.lmstudio) },
                    set: { settings.setLLMEnabled(.lmstudio, enabled: $0) }
                )) {
                    Text("LMStudio")
                }
                TextField("Base URL", text: Binding(
                    get: { UserDefaults.standard.string(forKey: "lmstudio_base_url") ?? "http://192.168.0.1:1234" },
                    set: { UserDefaults.standard.set($0, forKey: "lmstudio_base_url") }
                ))
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .background(content: { RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)) })

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
            }

            // Claude API Section
            Section(header: Text("Claude API")) {
                Toggle(isOn: Binding(
                    get: { settings.isLLMEnabled(.claude) },
                    set: { settings.setLLMEnabled(.claude, enabled: $0) }
                )) {
                    Text("Enable Claude")
                }
                TextField("API Key", text: Binding(
                    get: { UserDefaults.standard.string(forKey: "claude_api_key") ?? "" },
                    set: { UserDefaults.standard.set($0, forKey: "claude_api_key") }
                ))
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .background(content: { RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)) })

            }

            // OpenAI API Section
            Section(header: Text("OpenAI API")) {
                Toggle(isOn: Binding(
                    get: { settings.isLLMEnabled(.openai) },
                    set: { settings.setLLMEnabled(.openai, enabled: $0) }
                )) {
                    Text("Enable OpenAI")
                }
                TextField("API Key", text: Binding(
                    get: { UserDefaults.standard.string(forKey: "openai_api_key") ?? "" },
                    set: { UserDefaults.standard.set($0, forKey: "openai_api_key") }
                ))
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .background(content: { RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)) })
            }
            
            Section(header: Text("l_llm_instructions".localized), footer: Text("l_llm_instructions_desc".localized)) {
                TextEditor(text: Binding(
                    get: { UserDefaults.standard.string(forKey: "instruction") ?? "" },
                    set: { UserDefaults.standard.set($0, forKey: "instruction") }
                ))
                    .frame(minHeight: 100)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("l_temperature".localized), footer: Text("l_temperature_desc".localized)) {
                HStack {
                    Text(String(format: "%.1f", UserDefaults.standard.double(forKey: "temperature") != 0 ? UserDefaults.standard.double(forKey: "temperature") : 0.7))
                        .frame(width: 40)
                    Slider(value: Binding(
                        get: { UserDefaults.standard.double(forKey: "temperature") != 0 ? UserDefaults.standard.double(forKey: "temperature") : 0.7 },
                        set: { UserDefaults.standard.set($0, forKey: "temperature") }
                    ), in: 0.1...2.0, step: 0.1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section(header: Text("l_top_p".localized), footer: Text("l_top_p_desc".localized)) {
                HStack {
                    Text(String(format: "%.1f", UserDefaults.standard.double(forKey: "top_p") != 0 ? UserDefaults.standard.double(forKey: "top_p") : 0.9))
                        .frame(width: 40)
                    Slider(value: Binding(
                        get: { UserDefaults.standard.double(forKey: "top_p") != 0 ? UserDefaults.standard.double(forKey: "top_p") : 0.9 },
                        set: { UserDefaults.standard.set($0, forKey: "top_p") }
                    ), in: 0.1...1.0, step: 0.1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section(header: Text("l_top_k".localized), footer: Text("l_top_k_desc".localized)) {
                HStack {
                    Text("\(UserDefaults.standard.integer(forKey: "top_k") != 0 ? UserDefaults.standard.integer(forKey: "top_k") : 40)")
                        .frame(width: 40)
                    Slider(value: Binding(
                        get: { Double(UserDefaults.standard.integer(forKey: "top_k") != 0 ? UserDefaults.standard.integer(forKey: "top_k") : 40) },
                        set: { UserDefaults.standard.set(Int($0), forKey: "top_k") }
                    ), in: 1...100, step: 1)
                        .accentColor(Color.appPrimary)
                }
            }
            
            Section (header: Text("l_reset".localized), footer: Text("l_reset_llm_desc".localized)) {
                Button("l_reset_llm_settings".localized) {
                    UserDefaults.standard.set("", forKey: "ollama_base_url")
                    UserDefaults.standard.set("", forKey: "lmstudio_base_url")
                    UserDefaults.standard.set("", forKey: "claude_api_key")
                    UserDefaults.standard.set("", forKey: "openai_api_key")
                    UserDefaults.standard.set("l_default_instruction".localized, forKey: "instruction")
                    UserDefaults.standard.set(0.7, forKey: "temperature")
                    UserDefaults.standard.set(0.9, forKey: "top_p")
                    UserDefaults.standard.set(40, forKey: "top_k")
                    settings.setLLMEnabled(.ollama, enabled: true)
                    settings.setLLMEnabled(.lmstudio, enabled: false)
                    settings.setLLMEnabled(.claude, enabled: false)
                    settings.setLLMEnabled(.openai, enabled: false)
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
        .alert("l_server_connection_failed".localized, isPresented: $showConfirmationAlert) {
            Button("l_cancel".localized, role: .cancel) {}
            Button("l_save_anyway".localized, role: .destructive) {
                NotificationCenter.default.post(
                    name: Notification.Name("OllamaServerURLChanged"),
                    object: nil,
                    userInfo: ["url": UserDefaults.standard.string(forKey: "ollama_base_url") ?? ""]
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
        let baseURL = UserDefaults.standard.string(forKey: "ollama_base_url") ?? ""
        
        if let url = URL(string: baseURL) {
            let oldURLString = UserDefaults.standard.string(forKey: "ollama_base_url")
            
            if oldURLString != baseURL {
                isSaving = true
                
                Task {
                    do {
                        UserDefaults.standard.set(baseURL, forKey: "ollama_base_url")
                        UserDefaults.standard.set("ollama", forKey: "last_used_llm")
                        
                        let testBridge = LLMBridge()
                        let models = await testBridge.getAvailableModels()
                        
                        await MainActor.run {
                            isSaving = false
                            
                            if !models.isEmpty {
                                NotificationCenter.default.post(
                                    name: Notification.Name("OllamaServerURLChanged"),
                                    object: nil,
                                    userInfo: ["url": baseURL]
                                )
                                
                                showToast("l_server_check_complete".localized)
                            } else {
                                showConfirmationAlert = true
                            }
                        }
                    } catch {
                        isSaving = false
                        showToast(String(format: "l_connection_error".localized, error.localizedDescription))
                    }
                }
            } else {
                showToast("l_server_check_complete".localized)
            }
        } else {
            showToast("l_url_format_invalid".localized)
        }
    }
    
    private func checkOllamaConnection() {
        let baseURL = UserDefaults.standard.string(forKey: "ollama_base_url") ?? ""
        guard let url = URL(string: baseURL) else {
            showToast("l_connection_error".localized)
            return
        }
        
        isCheckingConnection = true
        Task {
            let originalOllamaURL = UserDefaults.standard.string(forKey: "ollama_base_url")
            let originalLLM = UserDefaults.standard.string(forKey: "last_used_llm")
            
            UserDefaults.standard.set(baseURL, forKey: "ollama_base_url")
            UserDefaults.standard.set("ollama", forKey: "last_used_llm")
            
            let testBridge = LLMBridge()
            let models = await testBridge.getAvailableModels()
            if models.isEmpty {
                showToast("l_connection_error".localized)
            } else {
                showToast("l_connected_to_server".localized)
            }
            
            if let originalURL = originalOllamaURL {
                UserDefaults.standard.set(originalURL, forKey: "ollama_base_url")
            }
            if let originalTarget = originalLLM {
                UserDefaults.standard.set(originalTarget, forKey: "last_used_llm")
            }
            isCheckingConnection = false
        }
    }
    
    private func checkLMStudioConnection() {
        let baseURL = UserDefaults.standard.string(forKey: "lmstudio_base_url") ?? ""
        guard let url = URL(string: baseURL) else {
            showToast("l_connection_error".localized)
            return
        }
        
        isCheckingLMStudioConnection = true
        Task {
            let originalLMStudioURL = UserDefaults.standard.string(forKey: "lmstudio_base_url")
            let originalLLM = UserDefaults.standard.string(forKey: "last_used_llm")
            
            UserDefaults.standard.set(baseURL, forKey: "lmstudio_base_url")
            UserDefaults.standard.set("lmstudio", forKey: "last_used_llm")
            
            let testBridge = LLMBridge()
            let models = await testBridge.getAvailableModels()
            if models.isEmpty {
                showToast("l_connection_error".localized)
            } else {
                showToast("l_connected_to_server".localized)
            }
            
            if let originalURL = originalLMStudioURL {
                UserDefaults.standard.set(originalURL, forKey: "lmstudio_base_url")
            }
            if let originalTarget = originalLLM {
                UserDefaults.standard.set(originalTarget, forKey: "last_used_llm")
            }
            isCheckingLMStudioConnection = false
        }
    }
    
    private func deleteAllData() {
        isDeletingData = true
        
        Task {
            do {
                try databaseService.clearAllConversations()
                
                await MainActor.run {
                    isDeletingData = false
                    showToast("l_all_data_deleted".localized)
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("ConversationDataChanged"),
                        object: nil
                    )
                }
            } catch {
                await MainActor.run {
                    isDeletingData = false
                    showToast(String(format: "l_data_deletion_failed".localized, error.localizedDescription))
                }
            }
        }
    }
}

struct LLMRowView: View {
    let llm: LLMTarget
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconForLLM(llm))
                .foregroundColor(colorForLLM(llm))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(llm.displayName)
                    .font(.subheadline)
                
                Text(llm.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
    }
    
    private func iconForLLM(_ llm: LLMTarget) -> String {
        switch llm {
        case .ollama:
            return "cpu"
        case .lmstudio:
            return "laptopcomputer"
        case .claude:
            return "brain.head.profile"
        case .openai:
            return "globe"
        }
    }
    
    private func colorForLLM(_ llm: LLMTarget) -> Color {
        switch llm {
        case .ollama:
            return .blue
        case .lmstudio:
            return .purple
        case .claude:
            return .orange
        case .openai:
            return .green
        }
    }
}
