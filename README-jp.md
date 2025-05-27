# LLM Client - for Ollama

[ENGLISH](README.md) | [한국어](README-ko.md)

MyOllama3は、SwiftUIで開発されたiOSアプリケーションで、ローカルまたはリモートのOllamaサーバーに接続して対話型AIチャットボット機能を提供します。

![poster](./captures.jpg)

## 🎁 アプリをダウンロード

- ビルドが難しい方は、以下のリンクからアプリをダウンロードできます。
- [https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481](https://apps.apple.com/us/app/llm-client-for-ollama/id6738298481)


## 📱 プロジェクト紹介

このアプリは**プライバシー保護**を重視するユーザーのための**ローカルAI対話アプリケーション**です。Ollama APIを通じてローカルで動作する大規模言語モデル（LLM）と相互作用できる直感的なインターフェースを提供し、すべての会話内容はユーザーのデバイスにのみ安全に保存されます。

## ✨ 主要機能

### 🤖 AI対話機能
- **リアルタイムストリーミング応答**: 高速なリアルタイムAI応答
- **多様なモデルサポート**: Ollamaが提供するすべてのAIモデル（Llama、Mistral、Qwen、CodeLlamaなど）
- **マルチモーダル対話**: 画像添付およびビジョンモデルによる画像分析
- **応答生成キャンセル**: いつでもAI応答生成を中断可能

### 📚 対話管理
- **永続保存**: SQLiteデータベースを利用したすべての対話履歴の自動保存
- **対話検索**: キーワードベースの対話内容検索
- **対話復元**: 以前の対話の読み込みと継続
- **サーバー別管理**: 異なるOllamaサーバーとの対話を区別して管理
- **メッセージ管理**: 個別メッセージのコピー、共有、削除機能

### ⚙️ 高度な設定
- **AIパラメータ調整**: Temperature、Top P、Top Kなどの細かい調整
- **カスタム指示**: AI行動方式のためのシステムプロンプト設定
- **サーバー接続管理**: 複数のOllamaサーバーサポートと接続状態確認
- **リアルタイム設定適用**: アプリ再起動なしに設定変更を即座に反映

### 🌍 ユーザーエクスペリエンス
- **多言語対応**: 韓国語、英語、日本語の完全ローカライゼーション
- **ダークモードサポート**: システムテーマに応じた自動カラー適応
- **直感的なUI**: メッセージバブル、コンテキストメニュー、ハプティックフィードバック
- **アクセシビリティ**: VoiceOverおよびアクセシビリティ機能サポート

## 🏗️ アーキテクチャ構造

```
myollama3/
├── 📱 UI Views
│   ├── ContentView.swift          # メイン画面（対話リストと新規対話）
│   ├── ChatView.swift            # チャットインターフェース（リアルタイム対話）
│   ├── SettingsView.swift        # 設定画面（サーバーとAIパラメータ）
│   ├── WelcomeView.swift         # オンボーディング画面（初回起動ガイド）
│   └── AboutView.swift           # アプリ情報と使用ガイド
│
├── 🧩 Components
│   ├── MessageBubble.swift       # メッセージバブルUI（Markdownレンダリング）
│   ├── MessageInputView.swift    # メッセージ入力欄（画像添付サポート）
│   └── ShareSheet.swift          # ネイティブ共有機能
│
├── ⚙️ Services
│   ├── OllamaService.swift       # Ollama API通信とストリーム処理
│   └── DatabaseService.swift    # SQLiteデータベース管理
│
├── 🔧 Utils & Extensions
│   ├── AppColor.swift           # 適応型カラーテーマ管理
│   ├── ImagePicker.swift        # カメラ/ギャラリー画像選択
│   ├── Localized.swift          # 多言語文字列拡張
│   └── KeyboardExtensions.swift # キーボード管理ユーティリティ
│
└── 🌍 Localization
    ├── ko.lproj/                # 韓国語（デフォルト）
    ├── en.lproj/                # 英語
    └── ja.lproj/                # 日本語
```

## 🛠️ 技術スタック

### フレームワークとライブラリ
- **Swift & SwiftUI**: ネイティブiOS開発
- **Combine**: リアクティブプログラミングと状態管理
- **SQLite**: ローカルデータベース（Raw SQL）
- **URLSession**: 非同期ネットワーク通信（async/await）
- **MarkdownUI**: Markdownテキストレンダリング
- **Toasts**: ユーザー通知表示

### 核心技術
- **AsyncSequence**: リアルタイムストリーミングデータ処理
- **PhotosUI**: 画像選択と処理
- **UIKit Integration**: SwiftUIとUIKitの統合
- **UserDefaults**: アプリ設定の永続保存
- **NotificationCenter**: アプリ内イベント通信

## 💾 データベーススキーマ

```sql
CREATE TABLE IF NOT EXISTS questions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  groupid TEXT NOT NULL,          -- 対話グループID（UUID）
  instruction TEXT,               -- システム指示（オプション）
  question TEXT,                  -- ユーザー質問
  answer TEXT,                    -- AI応答
  image TEXT,                     -- Base64エンコードされた画像（オプション）
  created TEXT,                   -- 作成時間（ISO8601形式）
  engine TEXT,                    -- 使用されたAIモデル名
  baseurl TEXT                    -- OllamaサーバーURL
);
```

### データフィールド説明
- **groupid**: 対話をグループ化するUUID、一つの対話セッションを表す
- **instruction**: AI行動方式を指定するシステムプロンプト
- **image**: 添付された画像のBase64エンコード文字列
- **engine**: llama、mistral、qwenなど使用されたモデル名
- **baseurl**: 該当対話が行われたOllamaサーバーアドレス

## 🚀 使用方法

### 1. 初期設定
1. **Ollamaサーバー準備**: ローカルまたはネットワークでOllamaサーバーを実行
2. **アプリ初回起動**: ウェルカム画面でサーバー設定ガイドを確認
3. **サーバーアドレス入力**: 設定 → Ollamaサーバー設定でURLを入力（例：`http://192.168.0.1:11434`）
4. **接続確認**: 「サーバー接続状態確認」ボタンで接続テスト

### 2. 対話開始
1. **新しい対話**: メイン画面で「新しい対話を開始」ボタンをタップ
2. **モデル選択**: 画面上部で使用するAIモデルを選択
3. **メッセージ入力**: 下部の入力欄に質問または指示を入力
4. **画像添付**: カメラアイコンで画像を追加（オプション）

### 3. 高度な機能
- **対話検索**: メイン画面の虫眼鏡アイコンで以前の対話を検索
- **メッセージ管理**: メッセージを長押ししてコピー、共有、削除メニューを表示
- **AIパラメータ調整**: 設定でTemperature、Top P、Top K値を調整
- **対話共有**: 全体の対話または個別の質問-回答をテキストで共有

## ⚙️ AIパラメータ設定

### Temperature (0.1 ~ 2.0)
- **低い値（0.1-0.5）**: 一貫性があり予測可能な応答
- **中間値（0.6-0.9）**: バランスの取れた創造性と一貫性
- **高い値（1.0-2.0）**: 創造的で多様な応答

### Top P (0.1 ~ 1.0)
- 次のトークン選択時に確率分布の上位P%内でのみ選択
- 低いほど保守的、高いほど多様な応答

### Top K (1 ~ 100)
- 次のトークン選択時に確率の高いK個の候補からのみ選択
- 低いほど一貫性、高いほど創造性

## 🔧 Ollamaサーバー設定

### ローカルサーバー（macOS/Linux）
```bash
# Ollamaインストール
curl -fsSL https://ollama.ai/install.sh | sh

# サーバー起動（外部アクセス許可）
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# モデルダウンロード例
ollama pull llama2
ollama pull mistral
ollama pull qwen
```

### ネットワーク設定
- **ファイアウォール**: 11434ポートを開放
- **ルーター**: 必要に応じてポートフォワーディング設定
- **IPアドレス**: アプリ設定で正確なサーバーIPを入力

## 🌍 多言語対応

現在サポートしている言語:
- **韓国語**（デフォルト）- `ko.lproj`
- **英語** - `en.lproj`  
- **日本語** - `ja.lproj`

言語はデバイス設定に応じて自動選択され、すべてのUIテキストが完全にローカライズされています。

## 🔐 プライバシー保護

MyOllama3はユーザーのプライバシーを最優先にします：

- ✅ **ローカル保存**: すべての対話内容はユーザーのデバイスにのみ保存
- ✅ **外部送信なし**: 設定したOllamaサーバー以外にはデータ送信しない
- ✅ **ローカルAI処理**: すべてのAI処理はローカルOllamaサーバーで実行
- ✅ **暗号化**: SQLiteデータベースの基本セキュリティ適用
- ✅ **追跡なし**: ユーザー行動追跡や分析データ収集なし

## 📋 システム要件

- **iOS**: 16.0以上
- **Xcode**: 15.0以上（開発時）
- **Swift**: 5.9以上
- **ネットワーク**: ローカルネットワークで実行中のOllamaサーバー
- **ストレージ**: 最小50MB（対話履歴に応じて追加）

## 🚀 サポートモデル

Ollamaが提供するすべてのモデルをサポートします：

### 対話型モデル
- **Llama 2/3**: 汎用対話モデル
- **Mistral**: 高性能対話モデル
- **Qwen**: 多言語サポートモデル
- **Gemma**: Googleの軽量モデル

### 専門モデル
- **CodeLlama**: プログラミング専用
- **DeepSeek-Coder**: コーディング専門
- **LLaVA**: 画像認識モデル
- **Bakllava**: ビジョン-言語モデル

## 🛠️ 開発とビルド

### 開発環境セットアップ
1. **リポジトリクローン**
```bash
git clone https://github.com/yourusername/swift_myollama3.git
cd swift_myollama3
```

2. **Xcodeで開く**
```bash
open myollama3.xcodeproj
```

3. **依存関係インストール**
- プロジェクトはSwift Package Managerを使用
- Xcodeが自動的にパッケージ依存関係を解決

### 依存ライブラリ
- **MarkdownUI**: Markdownレンダリング
- **Toasts**: ユーザー通知表示

## 🐛 既知の問題

- iOS 16.0以下では一部のSwiftUI機能が制限される
- 非常に大きな画像はメモリ使用量が増加する可能性
- ネットワークが不安定な場合、ストリーミングが中断される可能性

## 🤝 貢献

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 変更履歴

主要なアップデート履歴は[CHANGELOG.md](CHANGELOG.md)を参照してください。

## 📄 ライセンス

このプロジェクトのライセンス情報は[LICENSE](LICENSE)ファイルを参照してください。

## 👨‍💻 開発者情報

- **開発者**: BillyPark
- **作成日**: 2025年5月9日
- **連絡先**: アプリ内の「開発者にフィードバックを送る」機能を利用

## 🙏 謝辞

- [Ollama](https://ollama.ai/) - ローカルLLMサーバー提供
- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) - Markdownレンダリング
- [Swift-Toasts](https://github.com/EnesKaraosman/Toast-SwiftUI) - 通知表示

---

**MyOllama3で安全でプライベートなAI対話を体験してください！🚀** 