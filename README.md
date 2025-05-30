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
- **Real-time Streaming Responses**: Fast real-time AI responses with streaming support
- **Multiple Model Support**: All AI models provided by Ollama (Llama, Mistral, Qwen, CodeLlama, etc.)
- **Multimodal Conversations**: Support for image attachments and image analysis through vision models
- **Document Processing**: PDF and text file upload and analysis capabilities
- **File Attachment Support**: Support for various file formats including images (JPG, PNG, GIF, etc.), PDF documents, and text files
- **Response Cancellation**: Ability to stop AI response generation at any time
- **Auto Image Resizing**: Automatic image compression and resizing for optimal performance

### 📚 Conversation Management
- **Persistent Storage**: Automatic saving of all conversation history using SQLite database
- **Conversation Search**: Keyword-based conversation content search functionality
- **Conversation Restoration**: Load and continue previous conversations seamlessly
- **Server-based Management**: Separate management of conversations with different Ollama servers
- **Message Management**: Copy, share, and delete individual messages with context menus
- **Full Conversation Export**: Export entire conversations as text for external use
- **Conversation Deletion**: Complete conversation removal with confirmation

### ⚙️ Advanced Settings
- **AI Parameter Adjustment**: Fine-tuning of Temperature (0.1-2.0), Top P (0.1-1.0), Top K (1-100)
- **Custom Instructions**: System prompt settings for AI behavior customization
- **Server Connection Management**: Support for multiple Ollama servers and real-time connection status monitoring
- **Settings Persistence**: All settings automatically saved and restored
- **Real-time Settings Application**: Immediate application of setting changes without app restart
- **Connection Testing**: Built-in server connectivity testing functionality
- **Data Management**: Complete conversation data deletion with confirmation

### 🌍 User Experience
- **Multilingual Support**: Complete localization in Korean, English, and Japanese
- **Dark Mode Support**: Automatic color adaptation based on system theme
- **Intuitive UI**: Message bubbles, context menus, haptic feedback, and responsive design
- **Accessibility**: VoiceOver and accessibility feature support
- **Camera Integration**: Direct camera access for image capture and analysis
- **Document Picker**: Native iOS document picker integration
- **Touch Gestures**: Long press for message actions, tap to dismiss keyboard
- **Loading States**: Visual feedback for all async operations

### 📎 File & Media Support
- **Image Formats**: JPG, JPEG, PNG, GIF, BMP, TIFF, HEIC, WebP
- **Document Formats**: PDF (with text extraction), TXT, RTF, Plain Text
- **Image Processing**: Automatic compression and Base64 encoding
- **PDF Text Extraction**: Full text extraction from PDF documents
- **File Preview**: Visual previews for attached files before sending
- **Multi-format Handling**: Intelligent file type detection and processing

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
│   ├── MessageInputView.swift    # Message input field (file attachment support)
│   ├── DocumentPicker.swift      # Document selection and processing
│   ├── CameraPicker.swift        # Camera integration component
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
- **Swift & SwiftUI**: Native iOS development with declarative UI
- **Combine**: Reactive programming and state management
- **SQLite**: Local database with raw SQL queries
- **URLSession**: Asynchronous network communication with async/await
- **MarkdownUI**: Advanced markdown text rendering
- **Toasts**: User notification and feedback display
- **PDFKit**: PDF document processing and text extraction
- **PhotosUI**: Advanced image selection and processing
- **UniformTypeIdentifiers**: File type detection and handling

### Core Technologies
- **AsyncSequence**: Real-time streaming data processing
- **UIKit Integration**: Seamless SwiftUI and UIKit integration
- **UserDefaults**: Persistent app settings storage
- **NotificationCenter**: In-app event communication and updates
- **Task Management**: Modern Swift concurrency for background operations
- **File System Access**: Secure file access with scoped resources

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
- **instruction**: System prompt specifying AI behavior and personality
- **image**: Base64 encoded string of attached image or document
- **engine**: Model name used (llama, mistral, qwen, etc.)
- **baseurl**: Ollama server address where the conversation took place

## 🚀 Usage

### 1. Initial Setup
1. **Prepare Ollama Server**: Run Ollama server locally or on network
2. **First App Launch**: Check server setup guide on welcome screen
3. **Enter Server Address**: Go to Settings → Ollama Server Settings and enter URL (e.g., `http://192.168.0.1:11434`)
4. **Connection Test**: Test connection with "Check Server Connection Status" button
5. **Configure AI Parameters**: Adjust Temperature, Top P, Top K values as needed

### 2. Starting a Conversation
1. **New Conversation**: Touch "Start New Conversation" button on main screen
2. **Model Selection**: Select AI model to use from dropdown menu
3. **Message Input**: Enter questions or instructions in bottom input field
4. **File Attachment**: Add images, PDFs, or text files using the paperclip icon
5. **Send Message**: Use arrow button or Enter key to send

### 3. Advanced Features
- **Conversation Search**: Search previous conversations with magnifying glass icon on main screen
- **Message Management**: Long press messages to show copy, share, delete menu
- **AI Parameter Adjustment**: Fine-tune Temperature, Top P, Top K values in settings
- **Conversation Sharing**: Share entire conversations or individual Q&A as text
- **Document Analysis**: Upload PDFs for text extraction and analysis
- **Image Analysis**: Attach images for visual analysis using vision models

### 4. File Management
- **Image Upload**: Camera or gallery selection with automatic resizing
- **PDF Processing**: Automatic text extraction from PDF documents
- **Text Files**: Support for various text file formats
- **File Preview**: Visual confirmation before sending attachments
- **File Removal**: Easy attachment removal before sending

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
ollama pull llava              # For image analysis
ollama pull codellama         # For code assistance
```

### Network Configuration
- **Firewall**: Open port 11434
- **Router**: Set up port forwarding if needed
- **IP Address**: Enter correct server IP in app settings
- **Connection Testing**: Use built-in connection test feature

## 🌍 Multilingual Support

Currently supported languages:
- **Korean** (default) - `ko.lproj`
- **English** - `en.lproj`  
- **Japanese** - `ja.lproj`

Language is automatically selected based on device settings, with all UI text and system messages fully localized.

## 🔐 Privacy Protection

MyOllama3 prioritizes user privacy:

- ✅ **Local Storage**: All conversation content stored only on user device
- ✅ **No External Transmission**: No data transmission except to configured Ollama server
- ✅ **Local AI Processing**: All AI processing performed on local Ollama server
- ✅ **File Security**: Secure file processing with scoped resource access
- ✅ **Encryption**: SQLite database default security applied
- ✅ **No Tracking**: No user behavior tracking or analytics data collection
- ✅ **Data Control**: Complete user control over data deletion

## 📋 System Requirements

- **iOS**: 16.0 or later
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later
- **Network**: Ollama server running on local network or remote server
- **Storage**: Minimum 100MB (additional space based on conversation history and attachments)
- **Memory**: Adequate RAM for image processing and PDF text extraction

## 🚀 Supported Models

Supports all models provided by Ollama:

### Conversational Models
- **Llama 2/3**: General conversation models with excellent performance
- **Mistral**: High-performance conversation model with multilingual support
- **Qwen**: Advanced multilingual support model with strong reasoning
- **Gemma**: Google's lightweight and efficient model

### Specialized Models
- **CodeLlama**: Programming and development assistance
- **DeepSeek-Coder**: Advanced coding specialist with multiple languages
- **LLaVA**: Image recognition and visual analysis model
- **Bakllava**: Advanced vision-language model for complex visual tasks

### Multimodal Models
- **LLaVA variants**: Image understanding and description
- **Bakllava**: Enhanced image and document analysis
- **Vision models**: Support for various vision-enabled models

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
- **MarkdownUI**: Advanced markdown rendering with syntax highlighting
- **Toasts**: User notification and feedback display
- **PDFKit**: Built-in PDF processing capabilities
- **PhotosUI**: Native iOS photo selection interface

## 🐛 Known Issues

- Some SwiftUI features limited on iOS 16.0 and below
- Very large images may increase memory usage temporarily
- Streaming may be interrupted during network instability
- PDF text extraction may vary based on PDF structure
- Camera access requires explicit user permission

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

- [Ollama](https://ollama.ai/) - Providing excellent local LLM server platform
- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) - Beautiful markdown rendering
- [Swift-Toasts](https://github.com/EnesKaraosman/Toast-SwiftUI) - User notification display
- [PDFKit](https://developer.apple.com/documentation/pdfkit) - Apple's PDF processing framework

---

**Experience safe and private AI conversations with advanced file support using MyOllama3! 🚀**