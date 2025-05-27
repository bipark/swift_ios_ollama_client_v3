# LLM Client - for Ollama

[ENGLISH](README.md) | [日本語](README-jp.md)

MyOllama3는 SwiftUI로 개발된 iOS 애플리케이션으로, 로컬 또는 원격 Ollama 서버와 연결하여 대화형 AI 챗봇 기능을 제공합니다.

![poster](./captures.jpg)

## 🎁 앱 다운로드

- 아래 링크에서 앱을 다운로드하실 수 있습니다.
- [https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481](https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481)


## 📱 프로젝트 소개

이 앱은 **개인정보 보호**를 중시하는 사용자를 위한 **로컬 AI 대화 애플리케이션**입니다. Ollama API를 통해 로컬에서 구동되는 대형 언어 모델(LLM)과 상호작용할 수 있는 직관적인 인터페이스를 제공하며, 모든 대화 내용은 사용자의 기기에만 안전하게 저장됩니다.

## ✨ 핵심 기능

### 🤖 AI 대화 기능
- **실시간 스트리밍 응답**: 빠른 속도의 실시간 AI 응답
- **다양한 모델 지원**: Ollama에서 제공하는 모든 AI 모델 (Llama, Mistral, Qwen, CodeLlama 등)
- **멀티모달 대화**: 이미지 첨부 및 비전 모델을 통한 이미지 분석
- **응답 생성 취소**: 언제든지 AI 응답 생성을 중단 가능

### 📚 대화 관리
- **영구 저장**: SQLite 데이터베이스를 이용한 모든 대화 내역 자동 저장
- **대화 검색**: 키워드 기반 대화 내용 검색
- **대화 복원**: 이전 대화 불러오기 및 계속하기
- **서버별 관리**: 서로 다른 Ollama 서버와의 대화 구분 관리
- **메시지 관리**: 개별 메시지 복사, 공유, 삭제 기능

### ⚙️ 고급 설정
- **AI 매개변수 조정**: Temperature, Top P, Top K 등 세밀한 조정
- **커스텀 지시사항**: AI 행동 방식을 위한 시스템 프롬프트 설정
- **서버 연결 관리**: 여러 Ollama 서버 지원 및 연결 상태 확인
- **실시간 설정 적용**: 앱 재시작 없이 설정 변경 즉시 반영

### 🌍 사용자 경험
- **다국어 지원**: 한국어, 영어, 일본어 완전 현지화
- **다크모드 지원**: 시스템 테마에 따른 자동 색상 적응
- **직관적인 UI**: 메시지 버블, 컨텍스트 메뉴, 햅틱 피드백
- **접근성**: VoiceOver 및 접근성 기능 지원

## 🏗️ 아키텍처 구조

```
myollama3/
├── 📱 UI Views
│   ├── ContentView.swift          # 메인 화면 (대화 목록 및 새 대화)
│   ├── ChatView.swift            # 채팅 인터페이스 (실시간 대화)
│   ├── SettingsView.swift        # 설정 화면 (서버 및 AI 매개변수)
│   ├── WelcomeView.swift         # 온보딩 화면 (첫 실행 안내)
│   └── AboutView.swift           # 앱 정보 및 사용 가이드
│
├── 🧩 Components
│   ├── MessageBubble.swift       # 메시지 버블 UI (마크다운 렌더링)
│   ├── MessageInputView.swift    # 메시지 입력창 (이미지 첨부 지원)
│   └── ShareSheet.swift          # 네이티브 공유 기능
│
├── ⚙️ Services
│   ├── OllamaService.swift       # Ollama API 통신 및 스트림 처리
│   └── DatabaseService.swift    # SQLite 데이터베이스 관리
│
├── 🔧 Utils & Extensions
│   ├── AppColor.swift           # 적응형 색상 테마 관리
│   ├── ImagePicker.swift        # 카메라/갤러리 이미지 선택
│   ├── Localized.swift          # 다국어 문자열 확장
│   └── KeyboardExtensions.swift # 키보드 관리 유틸리티
│
└── 🌍 Localization
    ├── ko.lproj/                # 한국어 (기본)
    ├── en.lproj/                # 영어
    └── ja.lproj/                # 일본어
```

## 🛠️ 기술 스택

### 프레임워크 및 라이브러리
- **Swift & SwiftUI**: 네이티브 iOS 개발
- **Combine**: 반응형 프로그래밍 및 상태 관리
- **SQLite**: 로컬 데이터베이스 (Raw SQL)
- **URLSession**: 비동기 네트워크 통신 (async/await)
- **MarkdownUI**: 마크다운 텍스트 렌더링
- **Toasts**: 사용자 알림 표시

### 핵심 기술
- **AsyncSequence**: 실시간 스트리밍 데이터 처리
- **PhotosUI**: 이미지 선택 및 처리
- **UIKit Integration**: SwiftUI와 UIKit 통합
- **UserDefaults**: 앱 설정 영구 저장
- **NotificationCenter**: 앱 내 이벤트 통신

## 💾 데이터베이스 스키마

```sql
CREATE TABLE IF NOT EXISTS questions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  groupid TEXT NOT NULL,          -- 대화 그룹 ID (UUID)
  instruction TEXT,               -- 시스템 지시사항 (선택적)
  question TEXT,                  -- 사용자 질문
  answer TEXT,                    -- AI 응답
  image TEXT,                     -- Base64 인코딩된 이미지 (선택적)
  created TEXT,                   -- 생성 시간 (ISO8601 형식)
  engine TEXT,                    -- 사용된 AI 모델명
  baseurl TEXT                    -- Ollama 서버 URL
);
```

### 데이터 필드 설명
- **groupid**: 대화를 그룹화하는 UUID, 하나의 대화 세션을 나타냄
- **instruction**: AI 행동 방식을 지정하는 시스템 프롬프트
- **image**: 첨부된 이미지의 Base64 인코딩 문자열
- **engine**: llama, mistral, qwen 등 사용된 모델명
- **baseurl**: 해당 대화가 이루어진 Ollama 서버 주소

## 🚀 사용 방법

### 1. 초기 설정
1. **Ollama 서버 준비**: 로컬 또는 네트워크에서 Ollama 서버 실행
2. **앱 첫 실행**: 웰컴 화면에서 서버 설정 안내 확인
3. **서버 주소 입력**: 설정 → Ollama 서버 설정에서 URL 입력 (예: `http://192.168.0.1:11434`)
4. **연결 확인**: "서버연결 상태 확인" 버튼으로 연결 테스트

### 2. 대화 시작
1. **새 대화**: 메인 화면에서 "새 대화 시작하기" 버튼 터치
2. **모델 선택**: 화면 상단에서 사용할 AI 모델 선택
3. **메시지 입력**: 하단 입력창에 질문 또는 지시사항 입력
4. **이미지 첨부**: 카메라 아이콘으로 이미지 추가 (선택적)

### 3. 고급 기능
- **대화 검색**: 메인 화면에서 돋보기 아이콘으로 이전 대화 검색
- **메시지 관리**: 메시지 길게 누르기로 복사, 공유, 삭제 메뉴 표시
- **AI 매개변수 조정**: 설정에서 Temperature, Top P, Top K 값 조정
- **대화 공유**: 전체 대화 또는 개별 질문-답변을 텍스트로 공유

## ⚙️ AI 매개변수 설정

### Temperature (0.1 ~ 2.0)
- **낮은 값 (0.1-0.5)**: 일관되고 예측 가능한 응답
- **중간 값 (0.6-0.9)**: 균형잡힌 창의성과 일관성
- **높은 값 (1.0-2.0)**: 창의적이고 다양한 응답

### Top P (0.1 ~ 1.0)
- 다음 토큰 선택 시 확률 분포의 상위 P% 내에서만 선택
- 낮을수록 보수적, 높을수록 다양한 응답

### Top K (1 ~ 100)
- 다음 토큰 선택 시 확률이 높은 K개 후보 중에서만 선택
- 낮을수록 일관성, 높을수록 창의성

## 🔧 Ollama 서버 설정

### 로컬 서버 (macOS/Linux)
```bash
# Ollama 설치
curl -fsSL https://ollama.ai/install.sh | sh

# 서버 시작 (외부 접근 허용)
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# 모델 다운로드 예시
ollama pull llama2
ollama pull mistral
ollama pull qwen
```

### 네트워크 설정
- **방화벽**: 11434 포트 개방
- **라우터**: 필요시 포트 포워딩 설정
- **IP 주소**: 앱 설정에서 정확한 서버 IP 입력

## 🌍 다국어 지원

현재 지원 언어:
- **한국어** (기본) - `ko.lproj`
- **영어** - `en.lproj`  
- **일본어** - `ja.lproj`

언어는 기기 설정에 따라 자동 선택되며, 모든 UI 텍스트가 완전히 현지화되어 있습니다.

## 🔐 개인정보 보호

MyOllama3는 사용자의 프라이버시를 최우선으로 합니다:

- ✅ **로컬 저장**: 모든 대화 내용은 사용자 기기에만 저장
- ✅ **외부 전송 없음**: 설정한 Ollama 서버 외에는 데이터 전송하지 않음
- ✅ **로컬 AI 처리**: 모든 AI 처리는 로컬 Ollama 서버에서 수행
- ✅ **암호화**: SQLite 데이터베이스 기본 보안 적용
- ✅ **추적 없음**: 사용자 행동 추적이나 분석 데이터 수집 없음

## 📋 시스템 요구사항

- **iOS**: 16.0 이상
- **Xcode**: 15.0 이상 (개발 시)
- **Swift**: 5.9 이상
- **네트워크**: 로컬 네트워크에서 실행 중인 Ollama 서버
- **저장공간**: 최소 50MB (대화 내역에 따라 추가)

## 🚀 지원 모델

Ollama에서 제공하는 모든 모델을 지원합니다:

### 대화형 모델
- **Llama 2/3**: 범용 대화 모델
- **Mistral**: 고성능 대화 모델
- **Qwen**: 다국어 지원 모델
- **Gemma**: Google의 경량 모델

### 전문 모델
- **CodeLlama**: 프로그래밍 전용
- **DeepSeek-Coder**: 코딩 전문
- **LLaVA**: 이미지 인식 모델
- **Bakllava**: 비전-언어 모델

## 🛠️ 개발 및 빌드

### 개발 환경 설정
1. **저장소 클론**
```bash
git clone https://github.com/yourusername/swift_myollama3.git
cd swift_myollama3
```

2. **Xcode에서 열기**
```bash
open myollama3.xcodeproj
```

3. **의존성 설치**
- 프로젝트는 Swift Package Manager를 사용
- Xcode가 자동으로 패키지 의존성 해결

### 의존성 라이브러리
- **MarkdownUI**: 마크다운 렌더링
- **Toasts**: 사용자 알림 표시

## 🐛 알려진 이슈

- iOS 16.0 이하에서는 일부 SwiftUI 기능 제한
- 매우 큰 이미지는 메모리 사용량 증가 가능
- 네트워크 불안정 시 스트리밍 중단될 수 있음

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 변경사항

주요 업데이트 내역은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.

## 📄 라이센스

이 프로젝트의 라이센스 정보는 [LICENSE](LICENSE) 파일을 참조하세요.

## 👨‍💻 개발자 정보

- **개발자**: BillyPark
- **생성일**: 2025년 5월 9일
- **연락처**: 앱 내 "개발자에게 피드백 보내기" 기능 이용

## 🙏 감사의 글

- [Ollama](https://ollama.ai/) - 로컬 LLM 서버 제공
- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) - 마크다운 렌더링
- [Swift-Toasts](https://github.com/EnesKaraosman/Toast-SwiftUI) - 알림 표시

---

**MyOllama3로 안전하고 프라이빗한 AI 대화를 경험해보세요! 🚀**