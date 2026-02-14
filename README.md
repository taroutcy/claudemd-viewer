# ClaudeMD Viewer

> macOS メニューバーから全プロジェクトの CLAUDE.md をプレビュー＆切り替え。
> GitHub リポジトリの CLAUDE.md も URL を貼るだけで閲覧可能。

---

## 日本語

### 概要

**ClaudeMD Viewer** は、macOS メニューバーに常駐する軽量な CLAUDE.md ビューアーです。ローカルプロジェクトの CLAUDE.md を一覧・プレビューし、GitHub 上の他者のリポジトリの CLAUDE.md も URL 入力で取得・閲覧できます。

### 主要機能

- **メニューバー常駐**: Dock に表示せず、メニューバーアイコンからクイックアクセス
- **グローバルショートカット**: `⌘⇧M` でどこからでもポップオーバーを表示
- **ローカルプロジェクト一覧**: 指定フォルダを自動スキャンし、CLAUDE.md を検出
- **GitHub リポジトリ対応**: URL を貼り付けるだけで GitHub の CLAUDE.md を取得・ブックマーク
- **マークダウンプレビュー**: 見出し、リスト、コードブロックなどをレンダリング
  - 5分間のキャッシング機構で高速表示
  - ファイル更新時の自動キャッシュ無効化
- **複数 .md ファイル対応**: プロジェクト内の全 .md ファイルを横スクロールタブで切り替え
  - 各ファイルを個別にピン留め可能
  - レースコンディション防止機構で安全な非同期読み込み
- **トークン数推定**: CLAUDE.md の概算トークン数を表示（2500 トークン基準で色分け）
- **クイックアクション**:
  - コピー、システムデフォルトエディタで開く、ターミナル起動、Finder で開く（ローカル）
  - コピー、GitHub で開く、.md 保存（GitHub）
- **検索機能**: プロジェクト名と CLAUDE.md の内容をインクリメンタル検索
- **ピン留め**: 重要なプロジェクト・個別の .md ファイルをリストの上部に固定

### インストール

1. [Releases](https://github.com/taroutcy/claudemd-viewer/releases) から最新の DMG をダウンロード
2. DMG を開き、ClaudeMD Viewer.app を Applications フォルダにドラッグ
3. アプリを起動し、メニューバーのアイコンをクリック

### 使い方

#### ローカルプロジェクト

1. メニューバーのアイコンをクリック（または `⌘⇧M`）
2. **My Projects** タブでプロジェクト一覧を確認
3. プロジェクトをクリックして CLAUDE.md をプレビュー
4. アクションボタンでコピー、編集、ターミナル起動など

#### GitHub リポジトリ

1. **GitHub** タブに移動
2. GitHub リポジトリの URL を入力（例: `https://github.com/vercel/next.js`）
3. **Fetch** をクリックして CLAUDE.md を取得
4. ブックマークからいつでもアクセス可能

#### 設定

- 歯車アイコンから設定画面を開く
- **スキャンフォルダ**: 複数のフォルダを指定可能
- **スキャン深度**: 1〜10階層まで設定可能
- **スキャン間隔**: 5分/10分/30分から選択
- **除外パターン**: node_modules, .git などを自動除外（デフォルト設定）
- **ログイン時起動**: ON/OFF 切り替え（macOS 13+ 対応）

### 技術スタック

- **言語**: Swift 5.9+
- **UI**: SwiftUI (macOS 12+)
- **アーキテクチャ**: MVVM パターン
- **メニューバー**: AppKit (NSStatusItem + NSPopover)
- **グローバルショートカット**: Carbon (RegisterEventHotKey) - `⌘⇧M` 固定
- **マークダウンレンダリング**: apple/swift-markdown + カスタムレンダラー
  - 5分間のキャッシング機構
  - 非同期レンダリング (Task.detached)
- **HTTP クライアント**: URLSession (GitHub API)
- **データ永続化**: UserDefaults
- **配布**: DMG (GitHub Releases)
- **ライセンス**: MIT
- **対応 OS**: macOS 12 (Monterey) 以降
- **対応アーキテクチャ**: Apple Silicon + Intel (Universal Binary)

### ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照

---

## English

### Overview

**ClaudeMD Viewer** is a lightweight CLAUDE.md viewer that resides in the macOS menu bar. It lists and previews CLAUDE.md files from local projects and can fetch and view CLAUDE.md from GitHub repositories via URL input.

### Key Features

- **Menu bar resident**: Quick access from menu bar icon without Dock icon
- **Global shortcut**: Press `⌘⇧M` to toggle popover from anywhere
- **Local project list**: Auto-scan specified folders and detect CLAUDE.md
- **GitHub repository support**: Paste URL to fetch CLAUDE.md from GitHub repos
- **Markdown preview**: Render headings, lists, code blocks, etc.
  - 5-minute caching mechanism for fast rendering
  - Automatic cache invalidation on file updates
- **Multiple .md file support**: Switch between all .md files in project via horizontal scroll tabs
  - Individual file pinning
  - Race condition prevention for safe async loading
- **Token estimation**: Display estimated token count with color coding (2500 token baseline)
- **Quick actions**:
  - Copy, Open in system default editor, Launch terminal, Open in Finder (local)
  - Copy, Open on GitHub, Save .md (GitHub)
- **Search**: Incremental search across project names and CLAUDE.md content
- **Pin**: Pin important projects and individual .md files to the top of the list

### Installation

1. Download the latest DMG from [Releases](https://github.com/taroutcy/claudemd-viewer/releases)
2. Open the DMG and drag ClaudeMD Viewer.app to Applications folder
3. Launch the app and click the menu bar icon

### Usage

#### Local Projects

1. Click the menu bar icon (or press `⌘⇧M`)
2. Check project list in **My Projects** tab
3. Click a project to preview CLAUDE.md
4. Use action buttons to copy, edit, launch terminal, etc.

#### GitHub Repositories

1. Navigate to **GitHub** tab
2. Enter GitHub repository URL (e.g., `https://github.com/vercel/next.js`)
3. Click **Fetch** to retrieve CLAUDE.md
4. Access anytime from bookmarks

#### Settings

- Open settings from gear icon
- **Scan folders**: Specify multiple folders
- **Scan depth**: Set from 1 to 10 directory levels
- **Scan interval**: Choose 5min/10min/30min
- **Exclude patterns**: Auto-exclude node_modules, .git, etc. (default settings)
- **Launch at login**: ON/OFF toggle (macOS 13+ support)

### Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI (macOS 12+)
- **Architecture**: MVVM pattern
- **Menu bar**: AppKit (NSStatusItem + NSPopover)
- **Global shortcut**: Carbon (RegisterEventHotKey) - `⌘⇧M` fixed
- **Markdown rendering**: apple/swift-markdown + custom renderer
  - 5-minute caching mechanism
  - Async rendering (Task.detached)
- **HTTP client**: URLSession (GitHub API)
- **Data persistence**: UserDefaults
- **Distribution**: DMG (GitHub Releases)
- **License**: MIT
- **OS support**: macOS 12 (Monterey) or later
- **Architecture**: Apple Silicon + Intel (Universal Binary)

### License

MIT License - See [LICENSE](LICENSE) for details
