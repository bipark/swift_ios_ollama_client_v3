# LLM Client - for Ollama

[한국어](README-ko.md) | [日本語](README-jp.md) | English

MyOllama3 is an iOS application developed with SwiftUI that provides conversational AI chatbot functionality by connecting to local or remote Ollama servers.

![poster](./captures.jpg)

## 🎁 Download App 

- For those who have difficulty building, you can download the app from the link below.
- [https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481](https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481)

## 📱 Project Overview

This app is a **local AI conversation application** designed for users who prioritize **privacy protection**. It provides an intuitive interface for interacting with large language models (LLM) running locally through the Ollama API, with all conversation content securely stored only on the user's device.

## ✨ Core Features

### 🤖 AI Conversation Features
- **Real-time Streaming Responses**: Fast real-time AI responses
- **Multiple Model Support**: All AI models provided by Ollama (Llama, Mistral, Qwen, CodeLlama, etc.)
- **Multimodal Conversations**: Image attachments and image analysis through vision models
- **Response Cancellation**: Ability to stop AI response generation at any time

### 📚 Conversation Management
- **Persistent Storage**: Automatic saving of all conversation history using SQLite database
- **Conversation Search**: Keyword-based conversation content search
- **Conversation Restoration**: Load and continue previous conversations
- **Server-based Management**: Separate management of conversations with different Ollama servers
- **Message Management**: Copy, share, and delete individual messages

### ⚙️ Advanced Settings
- **AI Parameter Adjustment**: Fine-tuning of Temperature, Top P, Top K, etc.
- **Custom Instructions**: System prompt settings for AI behavior customization
- **Server Connection Management**: Support for multiple Ollama servers and connection status monitoring
- **Real-time Settings Application**: Immediate application of setting changes without app restart

### 🌍 User Experience
- **Multilingual Support**: Complete localization in Korean, English, and Japanese
- **Dark Mode Support**: Automatic color adaptation based on system theme
- **Intuitive UI**: Message bubbles, context menus, haptic feedback
- **Accessibility**: VoiceOver and accessibility feature support

## 🏗️ Architecture Structure

```
myollama3/
├── 📱 UI Views
│   ├── ContentView.swift          # Main screen (conversation list and new conversation)
│   ├── ChatView.swift            # Chat interface (real-time conversation)
│   ├── SettingsView.swift        # Settings screen (server and AI parameters)
│   ├── WelcomeView.swift         # Onboarding screen (first launch guide)
│   └── AboutView.swift           # App information and usage guide
│
├── 🧩 Components
│   ├── MessageBubble.swift       # Message bubble UI (markdown rendering)
│   ├── MessageInputView.swift    # Message input field (image attachment support)
│   └── ShareSheet.swift          # Native sharing functionality
│
├── ⚙️ Services
│   ├── OllamaService.swift       # Ollama API communication and stream processing
│   └── DatabaseService.swift    # SQLite database management
│
├── 🔧 Utils & Extensions
│   ├── AppColor.swift           # Adaptive color theme management
│   ├── ImagePicker.swift        # Camera/gallery image selection
│   ├── Localized.swift          # Multilingual string extensions
│   └── KeyboardExtensions.swift # Keyboard management utilities
│
└── 🌍 Localization
    ├── ko.lproj/                # Korean (default)
    ├── en.lproj/                # English
    └── ja.lproj/                # Japanese
```

## 🛠️ Technology Stack

### Frameworks and Libraries
- **Swift & SwiftUI**: Native iOS development
- **Combine**: Reactive programming and state management
- **SQLite**: Local database (Raw SQL)
- **URLSession**: Asynchronous network communication (async/await)
- **MarkdownUI**: Markdown text rendering
- **Toasts**: User notification display

### Core Technologies
- **AsyncSequence**: Real-time streaming data processing
- **PhotosUI**: Image selection and processing
- **UIKit Integration**: SwiftUI and UIKit integration
- **UserDefaults**: Persistent app settings storage
- **NotificationCenter**: In-app event communication

## 💾 Database Schema

```sql
CREATE TABLE IF NOT EXISTS questions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  groupid TEXT NOT NULL,          -- Conversation group ID (UUID)
  instruction TEXT,               -- System instructions (optional)
  question TEXT,                  -- User question
  answer TEXT,                    -- AI response
  image TEXT,                     -- Base64 encoded image (optional)
  created TEXT,                   -- Creation time (ISO8601 format)
  engine TEXT,                    -- AI model name used
  baseurl TEXT                    -- Ollama server URL
);
```

### Data Field Description
- **groupid**: UUID that groups conversations, representing one conversation session
- **instruction**: System prompt specifying AI behavior
- **image**: Base64 encoded string of attached image
- **engine**: Model name used (llama, mistral, qwen, etc.)
- **baseurl**: Ollama server address where the conversation took place

## 🚀 Usage

### 1. Initial Setup
1. **Prepare Ollama Server**: Run Ollama server locally or on network
2. **First App Launch**: Check server setup guide on welcome screen
3. **Enter Server Address**: Go to Settings → Ollama Server Settings and enter URL (e.g., `http://192.168.0.1:11434`)
4. **Connection Test**: Test connection with "Check Server Connection Status" button

### 2. Starting a Conversation
1. **New Conversation**: Touch "Start New Conversation" button on main screen
2. **Model Selection**: Select AI model to use from top of screen
3. **Message Input**: Enter questions or instructions in bottom input field
4. **Image Attachment**: Add images with camera icon (optional)

### 3. Advanced Features
- **Conversation Search**: Search previous conversations with magnifying glass icon on main screen
- **Message Management**: Long press messages to show copy, share, delete menu
- **AI Parameter Adjustment**: Adjust Temperature, Top P, Top K values in settings
- **Conversation Sharing**: Share entire conversations or individual Q&A as text

## ⚙️ AI Parameter Settings

### Temperature (0.1 ~ 2.0)
- **Low values (0.1-0.5)**: Consistent and predictable responses
- **Medium values (0.6-0.9)**: Balanced creativity and consistency
- **High values (1.0-2.0)**: Creative and diverse responses

### Top P (0.1 ~ 1.0)
- Selects only from top P% of probability distribution when choosing next token
- Lower values are more conservative, higher values yield more diverse responses

### Top K (1 ~ 100)
- Selects only from K highest probability candidates when choosing next token
- Lower values for consistency, higher values for creativity

## 🔧 Ollama Server Setup

### Local Server (macOS/Linux)
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start server (allow external access)
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# Example model downloads
ollama pull llama2
ollama pull mistral
ollama pull qwen
```

### Network Configuration
- **Firewall**: Open port 11434
- **Router**: Set up port forwarding if needed
- **IP Address**: Enter correct server IP in app settings

## 🌍 Multilingual Support

Currently supported languages:
- **Korean** (default) - `ko.lproj`
- **English** - `en.lproj`  
- **Japanese** - `ja.lproj`

Language is automatically selected based on device settings, with all UI text fully localized.

## 🔐 Privacy Protection

MyOllama3 prioritizes user privacy:

- ✅ **Local Storage**: All conversation content stored only on user device
- ✅ **No External Transmission**: No data transmission except to configured Ollama server
- ✅ **Local AI Processing**: All AI processing performed on local Ollama server
- ✅ **Encryption**: SQLite database default security applied
- ✅ **No Tracking**: No user behavior tracking or analytics data collection

## 📋 System Requirements

- **iOS**: 16.0 or later
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later
- **Network**: Ollama server running on local network
- **Storage**: Minimum 50MB (additional space based on conversation history)

## 🚀 Supported Models

Supports all models provided by Ollama:

### Conversational Models
- **Llama 2/3**: General conversation models
- **Mistral**: High-performance conversation model
- **Qwen**: Multilingual support model
- **Gemma**: Google's lightweight model

### Specialized Models
- **CodeLlama**: Programming-specific
- **DeepSeek-Coder**: Coding specialist
- **LLaVA**: Image recognition model
- **Bakllava**: Vision-language model

## 🛠️ Development and Build

### Development Environment Setup
1. **Clone Repository**
```bash
git clone https://github.com/yourusername/swift_myollama3.git
cd swift_myollama3
```

2. **Open in Xcode**
```bash
open myollama3.xcodeproj
```

3. **Install Dependencies**
- Project uses Swift Package Manager
- Xcode automatically resolves package dependencies

### Dependency Libraries
- **MarkdownUI**: Markdown rendering
- **Toasts**: User notification display

## 🐛 Known Issues

- Some SwiftUI features limited on iOS 16.0 and below
- Very large images may increase memory usage
- Streaming may be interrupted during network instability

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

For license information of this project, please refer to [LICENSE](LICENSE) file.

## 👨‍💻 Developer Information

- **Developer**: BillyPark
- **Created**: May 9, 2025
- **Contact**: Use "Send Feedback to Developer" feature in the app

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) - Providing local LLM server
- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) - Markdown rendering
- [Swift-Toasts](https://github.com/EnesKaraosman/Toast-SwiftUI) - Notification display

---

**Experience safe and private AI conversations with MyOllama3! 🚀**