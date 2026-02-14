# ClaudeMD Viewer — 製品仕様書 (Claude Code 実装用)

> macOS メニューバーから全プロジェクトの CLAUDE.md をプレビュー＆切り替え。
> GitHub リポジトリの CLAUDE.md も URL を貼るだけで閲覧可能。
> 無料 & オープンソース（MIT）、チップ制。

---

## 1. プロダクト概要

### コンセプト

メニューバーに常駐する軽量な CLAUDE.md ビューアー。ローカルプロジェクトの CLAUDE.md を一覧・プレビューし、GitHub 上の他者のリポジトリの CLAUDE.md も URL 入力で取得・閲覧できる。

### ターゲットユーザー

Claude Code を日常的に使う macOS 開発者。

### マネタイズ

完全無料。Stripe Donation Link による任意のチップ（「☕ Buy Dev a Coffee」ボタン）。

### 配布

- GitHub Releases（DMG インストーラー）
- MIT ライセンス
- ランディングページ（GitHub Pages）

---

## 2. 機能仕様

### 2.1 メニューバー常駐

- `NSStatusItem` でメニューバーにアイコンを表示
- アイコン: ドキュメント風の小さなアイコン（CLAUDE.md を表すシンプルな SVG）
- クリックで `NSPopover` を表示/非表示
- Dock にはアイコンを表示しない（`LSUIElement = true`）
- グローバルショートカット `Cmd+Shift+M` でどこからでもポップオーバーをトグル（Carbon `RegisterEventHotKey`）

### 2.2 タブ構成

ポップオーバー上部に 2 つのタブを配置。

| タブ | 内容 |
|------|------|
| **My Projects** | ローカルマシン上のプロジェクト一覧 |
| **GitHub** | URL 入力で取得した GitHub リポジトリの CLAUDE.md 一覧 |

### 2.3 My Projects タブ

#### プロジェクトスキャン

- 設定で指定したフォルダ（デフォルト: `~/Projects`, `~/Developer`, `~/Documents`）を再帰スキャン
- スキャン深度: デフォルト 3 階層
- スキャン間隔: デフォルト 10 分（手動リフレッシュボタンあり）
- 除外パターン: `node_modules`, `.git`, `vendor`, `venv`, `.venv`, `__pycache__`, `build`, `dist`, `.next`

#### プロジェクト検出条件

以下のいずれかを含むディレクトリをプロジェクトとして認識:

- `CLAUDE.md`
- `.claude/` ディレクトリ
- `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `build.gradle`, `Makefile` のいずれか

#### プロジェクト一覧表示

各プロジェクトは以下の情報を表示:

- プロジェクト名（ディレクトリ名。package.json の name があればそちらを優先）
- CLAUDE.md の有無（あり: ドキュメントアイコン / なし: 警告「!」マーク）
- 最終更新日（相対表示: 「2h ago」「3d ago」等）
- 推定トークン数（`文字数 ÷ 4` の概算）
- ピン留め状態（ピン留めしたプロジェクトは上部に固定）

#### 検索

- インクリメンタルサーチ（プロジェクト名 + CLAUDE.md の内容を対象）
- クリアボタン付き

#### 各プロジェクトの操作（一覧上）

- **クリック** → プレビュー画面へ遷移
- **ホバー** → 行の右端にゴミ箱アイコンを表示
- **ゴミ箱クリック** → 「Remove?」の確認ボタンに変化 → もう 1 回クリックで一覧から削除
- CLAUDE.md がないプロジェクトは薄い表示、クリック不可（「Create →」と表示）

#### フッター

- `{N} projects · {M} missing` のサマリー
- リフレッシュボタン（SVG 回転矢印アイコン）
- 設定ボタン（SVG 歯車アイコン）
- ☕ チップボタン（Stripe Donation Link を開く）

### 2.4 GitHub タブ

#### URL 入力

- 上部にテキスト入力フィールド + 「Fetch」ボタン
- GitHub リポジトリの URL を貼り付けて Enter or Fetch クリック
- ヒントテキスト: `e.g. https://github.com/vercel/next.js`

#### Fetch ロジック

1. 入力 URL から `{owner}` と `{repo}` を抽出
2. GitHub Raw Content API で CLAUDE.md を取得:
   ```
   GET https://raw.githubusercontent.com/{owner}/{repo}/main/CLAUDE.md
   ```
3. 404 の場合は `master` ブランチでリトライ:
   ```
   GET https://raw.githubusercontent.com/{owner}/{repo}/master/CLAUDE.md
   ```
4. それでも見つからない場合はエラートースト「CLAUDE.md not found in this repo」
5. 成功したらブックマークリストに追加し、ローカルにキャッシュ

#### 認証

- 認証なし（GitHub unauthenticated API: 60 requests/hour）
- フッターにレート制限の情報を表示: `GitHub API · no auth · 60 req/hr`

#### ブックマーク一覧

- 取得済みの GitHub リポジトリを一覧表示
- 各項目の表示: リポジトリ名、`owner/repo`、スター数（取得できれば）、取得日時
- アイコン: GitHub ロゴ（SVG）
- 検索: インクリメンタルサーチ（リポジトリ名 + owner + CLAUDE.md 内容）

#### 各ブックマークの操作

- **クリック** → プレビュー画面へ遷移
- **ホバー** → ゴミ箱アイコン表示
- **ゴミ箱クリック** → 「Remove?」確認 → 削除（ブックマークとキャッシュを削除）

### 2.5 プレビュー画面

プロジェクトまたは GitHub ブックマークをクリックした時の詳細表示。

#### ヘッダー

- ← 戻るボタン（SVG シェブロンアイコン）
- プロジェクト名 / リポジトリ名
- GitHub の場合: `owner/repo` と ⭐ スター数をサブテキストで表示
- 右端: リロードボタン（SVG 回転矢印アイコン）+ ゴミ箱アイコン
  - リロード: ローカルの場合はファイルを再読み込み、GitHub の場合は API から再取得
  - ゴミ箱: クリックで削除してリストに戻る

#### コンテンツ

- CLAUDE.md のマークダウンをレンダリング表示
- サポートする構文:
  - `#` / `##` 見出し
  - `-` リスト
  - `` ``` `` コードブロック（シンタックスハイライトは不要、背景色の区別のみ）
  - `` ` `` インラインコード
  - 通常のパラグラフ
- スクロール可能

#### トークンバー

- `◆ ~{N} tokens` の表示
- プログレスバー（2500 トークンを基準）
  - 緑: ~1000 以下
  - 黄: ~1000-2000
  - 赤: ~2000 以上

#### アクションボタン（ローカルプロジェクトの場合）

| ボタン | アイコン | 動作 |
|--------|---------|------|
| **Copy** | 重なった四角形 SVG（成功時: チェックマーク SVG） | CLAUDE.md の内容をクリップボードにコピー |
| **Edit** | ペンアイコン SVG | デフォルトエディタ（VS Code 等）で CLAUDE.md を開く |
| **Terminal** | ターミナルアイコン SVG | プロジェクトディレクトリで Terminal.app を開く |
| **Finder** | フォルダアイコン SVG | Finder でプロジェクトディレクトリを開く |

#### アクションボタン（GitHub ブックマークの場合）

| ボタン | アイコン | 動作 |
|--------|---------|------|
| **Copy** | 重なった四角形 SVG（成功時: チェックマーク SVG） | CLAUDE.md の内容をクリップボードにコピー |
| **GitHub** | 地球儀 SVG | ブラウザで GitHub リポジトリページを開く |
| **Save .md** | ダウンロード矢印 SVG | CLAUDE.md ファイルをローカルに保存（保存先選択ダイアログ） |

### 2.6 設定画面

| 項目 | 型 | デフォルト |
|------|-----|-----------|
| Scan Folders | URL リスト（追加/削除可能） | `~/Projects`, `~/Developer`, `~/Documents` |
| Scan Depth | 数値 | 3 |
| Scan Interval | 選択（5min / 10min / 30min） | 10 min |
| Global Shortcut | キーコンビネーション | `⌘⇧M` |
| Default Editor | 選択（VS Code / Cursor / Zed / System Default） | System Default |
| Launch at Login | トグル | ON |

フッター: 「About」「GitHub」「☕ Buy Dev a Coffee」リンク

### 2.7 トースト通知

操作結果のフィードバックをポップオーバー下部にトースト表示（1.8 秒で自動消去）:

- 「Copied to clipboard!」
- 「Scanning...」
- 「Reloading...」
- 「CLAUDE.md fetched ✓」
- 「CLAUDE.md not found in this repo」
- 「Removed from bookmarks」
- 「Removed from list」
- 「Opening in {editor name}...」
- 「Opening Terminal...」
- 「Opening Finder...」
- 「Opening GitHub...」
- 「Saved to {path}」
- 「Opening Stripe... ☕」

---

## 3. 技術仕様

### 3.1 技術スタック

| 項目 | 技術 |
|------|------|
| 言語 | Swift 5.9+ |
| UI | SwiftUI (macOS 12+) |
| メニューバー | AppKit (NSStatusItem + NSPopover) |
| グローバルショートカット | Carbon (RegisterEventHotKey) |
| マークダウンレンダリング | apple/swift-markdown → NSAttributedString |
| ファイル監視 | DispatchSource.makeFileSystemObjectSource or FSEvents |
| HTTP クライアント | URLSession（GitHub API 用） |
| トークン推定 | 文字数 ÷ 4 の概算 |
| データ永続化 | UserDefaults（設定 + GitHub ブックマーク） |
| 配布 | DMG（GitHub Releases） |
| ライセンス | MIT |
| 最小 OS | macOS 12 (Monterey) |
| 対応アーキテクチャ | Apple Silicon + Intel (Universal Binary) |

### 3.2 ディレクトリ構成

```
ClaudeMDViewer/
├── ClaudeMDViewerApp.swift      # @main エントリポイント
├── AppDelegate.swift               # NSStatusItem + NSPopover セットアップ
├── Info.plist                       # LSUIElement = true
│
├── Views/
│   ├── PopoverContentView.swift    # ルートビュー（タブ切り替え）
│   ├── TabBarView.swift            # My Projects / GitHub タブ
│   ├── ProjectListView.swift       # ローカルプロジェクト一覧
│   ├── GitHubListView.swift        # GitHub ブックマーク一覧 + URL 入力
│   ├── PreviewView.swift           # CLAUDE.md プレビュー + アクション
│   ├── SettingsView.swift          # 設定画面
│   ├── SearchBarView.swift         # 検索バー
│   ├── ProjectRowView.swift        # プロジェクト行コンポーネント
│   ├── ActionButtonView.swift      # アクションボタンコンポーネント
│   ├── TokenBarView.swift          # トークン表示バー
│   └── ToastView.swift             # トースト通知
│
├── Models/
│   ├── Project.swift               # ローカルプロジェクトモデル
│   ├── GitHubBookmark.swift        # GitHub ブックマークモデル
│   └── AppSettings.swift           # アプリ設定モデル
│
├── ViewModels/
│   ├── ProjectListViewModel.swift  # プロジェクト一覧の状態管理
│   ├── GitHubViewModel.swift       # GitHub 機能の状態管理
│   └── SettingsViewModel.swift     # 設定の状態管理
│
├── Services/
│   ├── ProjectScanner.swift        # ディレクトリスキャン
│   ├── FileWatcher.swift           # ファイル変更監視
│   ├── GitHubFetcher.swift         # GitHub API 通信
│   ├── MarkdownRenderer.swift      # MD → AttributedString 変換
│   └── TokenEstimator.swift        # トークン数推定
│
├── Utilities/
│   ├── HotKeyManager.swift         # グローバルショートカット管理
│   ├── ShellHelper.swift           # Terminal / Editor / Finder 起動
│   ├── ClipboardHelper.swift       # クリップボード操作
│   └── RelativeDateFormatter.swift # 「2h ago」形式の日付フォーマット
│
├── Assets.xcassets/                # メニューバーアイコン
├── build.sh                        # ビルドスクリプト
└── create_dmg.sh                   # DMG インストーラー作成スクリプト
```

### 3.3 データモデル

```swift
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: URL
    var claudeMdPath: URL?
    var localMdPath: URL?
    var lastModified: Date?
    var tokenEstimate: Int
    var hasClaudeDir: Bool
    var isPinned: Bool
    var claudeMdContent: String?
}

struct GitHubBookmark: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var owner: String
    var repo: String
    var url: String
    var stars: String?
    var fetchedAt: Date
    var tokenEstimate: Int
    var claudeMdContent: String
}

struct AppSettings: Codable {
    var scanFolders: [URL]
    var scanDepth: Int              // default: 3
    var scanIntervalMinutes: Int    // default: 10
    var excludePatterns: [String]   // default: ["node_modules", ".git", ...]
    var globalShortcut: String      // default: "⌘⇧M"
    var preferredEditor: EditorType // default: .systemDefault
    var launchAtLogin: Bool         // default: true
    var stripeDonationUrl: String   // Stripe Donation Link URL
}

enum EditorType: String, Codable, CaseIterable {
    case systemDefault = "System Default"
    case vscode = "VS Code"
    case cursor = "Cursor"
    case zed = "Zed"
}
```

### 3.4 主要ロジック

#### プロジェクトスキャン (ProjectScanner.swift)

```swift
func scanProjects(settings: AppSettings) async -> [Project] {
    var projects: [Project] = []

    for folder in settings.scanFolders {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { continue }

        for case let url as URL in enumerator {
            // 深度チェック
            let depth = url.pathComponents.count - folder.pathComponents.count
            if depth > settings.scanDepth {
                enumerator.skipDescendants()
                continue
            }

            // 除外パターンチェック
            if settings.excludePatterns.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            // ディレクトリ判定
            guard let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
                  isDir else { continue }

            // プロジェクト判定
            let claudeMd = url.appendingPathComponent("CLAUDE.md")
            let claudeDir = url.appendingPathComponent(".claude")
            let projectMarkers = ["package.json", "Cargo.toml", "pyproject.toml",
                                  "go.mod", "build.gradle", "Makefile"]

            let hasClaudeMd = FileManager.default.fileExists(atPath: claudeMd.path)
            let hasClaudeDir = FileManager.default.fileExists(atPath: claudeDir.path)
            let hasMarker = projectMarkers.contains {
                FileManager.default.fileExists(atPath: url.appendingPathComponent($0).path)
            }

            if hasClaudeMd || hasClaudeDir || hasMarker {
                let content = hasClaudeMd ? try? String(contentsOf: claudeMd) : nil
                let modDate = try? FileManager.default.attributesOfItem(
                    atPath: claudeMd.path
                )[.modificationDate] as? Date

                projects.append(Project(
                    id: UUID(),
                    name: projectName(for: url),
                    path: url,
                    claudeMdPath: hasClaudeMd ? claudeMd : nil,
                    localMdPath: fileIfExists(url.appendingPathComponent("CLAUDE.local.md")),
                    lastModified: modDate,
                    tokenEstimate: estimateTokens(content),
                    hasClaudeDir: hasClaudeDir,
                    isPinned: false,
                    claudeMdContent: content
                ))

                enumerator.skipDescendants() // プロジェクトルートを見つけたら子は不要
            }
        }
    }

    return projects.sorted { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }
}

private func projectName(for url: URL) -> String {
    let packageJson = url.appendingPathComponent("package.json")
    if let data = try? Data(contentsOf: packageJson),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let name = json["name"] as? String {
        return name
    }
    return url.lastPathComponent
}

private func estimateTokens(_ content: String?) -> Int {
    guard let content = content else { return 0 }
    return content.count / 4
}
```

#### GitHub Fetch (GitHubFetcher.swift)

```swift
func fetchClaudeMd(owner: String, repo: String) async throws -> String {
    let branches = ["main", "master"]

    for branch in branches {
        let urlString = "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/CLAUDE.md"
        guard let url = URL(string: urlString) else { continue }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }

    throw FetchError.notFound
}

func parseGitHubUrl(_ input: String) -> (owner: String, repo: String)? {
    // https://github.com/owner/repo 形式から owner と repo を抽出
    let cleaned = input
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "https://github.com/", with: "")
        .replacingOccurrences(of: "http://github.com/", with: "")
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    let parts = cleaned.split(separator: "/").map(String.init)
    guard parts.count >= 2 else { return nil }

    return (owner: parts[0], repo: parts[1])
}
```

#### エディタ / ターミナル起動 (ShellHelper.swift)

```swift
func openInEditor(_ fileUrl: URL, editor: EditorType) {
    switch editor {
    case .vscode:
        NSWorkspace.shared.open(
            [fileUrl],
            withApplicationAt: URL(fileURLWithPath: "/Applications/Visual Studio Code.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
    case .cursor:
        NSWorkspace.shared.open(
            [fileUrl],
            withApplicationAt: URL(fileURLWithPath: "/Applications/Cursor.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
    case .zed:
        NSWorkspace.shared.open(
            [fileUrl],
            withApplicationAt: URL(fileURLWithPath: "/Applications/Zed.app"),
            configuration: NSWorkspace.OpenConfiguration()
        )
    case .systemDefault:
        NSWorkspace.shared.open(fileUrl)
    }
}

func openTerminal(at directory: URL) {
    let script = """
    tell application "Terminal"
        activate
        do script "cd \(directory.path)"
    end tell
    """
    if let appleScript = NSAppleScript(source: script) {
        appleScript.executeAndReturnError(nil)
    }
}

func openInFinder(_ url: URL) {
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
}

func openUrl(_ urlString: String) {
    if let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)
    }
}
```

---

## 4. UI デザイン仕様

### 4.1 全体

- ポップオーバーサイズ: 幅 400px、最大高さ 560px
- 背景: 半透明ダーク（`rgba(28, 28, 32, 0.98)` + `blur(40px)`）
- 角丸: 12px
- ボーダー: `rgba(255, 255, 255, 0.08)` 1px
- シャドウ: `0 25px 60px rgba(0,0,0,0.6)`
- フォント: SF Pro Text / SF Pro Display（システムフォント）
- ダークモード固定（メニューバーアプリなので常にダーク）

### 4.2 カラーパレット

| 用途 | カラー |
|------|--------|
| 背景 | `#1c1c20` |
| テキスト（メイン） | `#eeeeee` |
| テキスト（セカンダリ） | `#999999` |
| テキスト（薄い） | `#4a4a55` |
| アクセント | `#c4a7ff`（紫） |
| ピン留めグラデーション | `#7c5cbf` → `#5b3e9e` |
| 成功 | `#7ac88a`（緑） |
| 警告 | `#e8c87a`（黄） |
| エラー・削除 | `#e06060`（赤） |
| コードブロック背景 | `#161625` |
| インラインコード文字 | `#e8c87a` |
| 見出し H2 | `#c4a7ff` |
| コードブロック文字 | `#a8d8a8` |

### 4.3 SVG アイコン一覧

全てのアイコンは 14-16px のストロークベース SVG。色は `currentColor` を使用してテーマに追従。

| 名前 | 用途 | 説明 |
|------|------|------|
| `doc` | プロジェクトアイコン、メニューバー | 角丸矩形 + 3 本の横線 |
| `github` | GitHub タブ、ブックマークアイコン | GitHub ロゴ（fill） |
| `search` | 検索バー | 虫眼鏡 |
| `copy` | コピーボタン | 重なった 2 つの矩形 |
| `check` | コピー成功 | チェックマーク |
| `edit` | エディタで開く | ペン（鉛筆） |
| `terminal` | ターミナルで開く | 矩形 + `>_` プロンプト |
| `folder` | Finder で開く | フォルダ |
| `refresh` | リロード / リフレッシュ | 循環する 2 本の矢印 |
| `globe` | GitHub を開く | 地球儀（円 + 経線 + 緯線） |
| `download` | .md を保存 | 下向き矢印 + 底線 |
| `trash` | 削除 | ゴミ箱 |
| `settings` | 設定 | 歯車（太陽型） |
| `back` | 戻る | 左シェブロン |

### 4.4 プレビュー画面レイアウト

```
┌─────────────────────────────────────────────┐
│  ← │ project-name              │  ⟳  │ 🗑  │  ← ヘッダー
│    │ owner/repo · ⭐ 92.5k     │     │     │    (GitHub のみサブテキスト)
├─────────────────────────────────────────────┤    (⟳ = リロード, 🗑 = 削除)
│                                             │
│  # Project Title                            │
│                                             │
│  ## SECTION HEADING                         │  ← マークダウンプレビュー
│  - List item with `inline code`             │    (スクロール可能)
│  - Another item                             │
│                                             │
│  ```                                        │
│  code block                                 │
│  ```                                        │
│                                             │
├─────────────────────────────────────────────┤
│  ◆ ~1240 tokens  [███████░░░░]              │  ← トークンバー
├─────────────────────────────────────────────┤
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐          │
│  │ 📋  │ │ ✏️  │ │ >_  │ │ 📁  │          │  ← アクションボタン
│  │Copy │ │Edit │ │Term │ │Find │          │    (ローカルの場合)
│  └─────┘ └─────┘ └─────┘ └─────┘          │
│                                             │
│  ┌─────┐ ┌─────┐ ┌─────┐                  │
│  │ 📋  │ │ 🌐  │ │ ⬇️  │                  │  ← アクションボタン
│  │Copy │ │ GH  │ │Save │                  │    (GitHub の場合)
│  └─────┘ └─────┘ └─────┘                  │
└─────────────────────────────────────────────┘
```

---

## 5. 開発ロードマップ

### Week 1: 基盤

- [ ] Xcode プロジェクト作成（Swift, SwiftUI, macOS 12+）
- [ ] `Info.plist` に `LSUIElement = true` を設定
- [ ] `AppDelegate.swift`: NSStatusItem + NSPopover セットアップ
- [ ] メニューバーアイコン（SVG → Template Image）
- [ ] ポップオーバーの基本表示/非表示
- [ ] タブ切り替え（My Projects / GitHub）
- [ ] `ProjectScanner.swift`: ディレクトリスキャン実装
- [ ] `ProjectListView.swift`: プロジェクト一覧表示

### Week 2: コア機能

- [ ] `SearchBarView.swift`: インクリメンタルサーチ
- [ ] `MarkdownRenderer.swift`: swift-markdown → AttributedString
- [ ] `PreviewView.swift`: CLAUDE.md プレビュー表示
- [ ] `TokenEstimator.swift`: トークン推定表示
- [ ] アクションボタン（Copy / Edit / Terminal / Finder）
- [ ] `ShellHelper.swift`: エディタ・ターミナル・Finder 起動
- [ ] `ClipboardHelper.swift`: クリップボードコピー
- [ ] 削除機能（確認付き 2 段階）
- [ ] リロードボタン（プレビューヘッダー内）

### Week 3: GitHub + 仕上げ

- [ ] `GitHubFetcher.swift`: URL パース + Raw Content API
- [ ] `GitHubListView.swift`: URL 入力 + ブックマーク一覧
- [ ] GitHub プレビューのアクションボタン（Copy / GitHub / Save .md）
- [ ] `SettingsView.swift`: 設定画面
- [ ] `HotKeyManager.swift`: グローバルショートカット (Cmd+Shift+M)
- [ ] `ToastView.swift`: トースト通知
- [ ] UserDefaults によるデータ永続化
- [ ] ピン留め機能
- [ ] `build.sh` / `create_dmg.sh` 作成
- [ ] テスト・バグ修正・ポリッシュ

### Week 4: リリース準備

- [ ] ランディングページ（GitHub Pages, 1 ページ HTML）
- [ ] README.md 作成
- [ ] Stripe Donation Link 設定
- [ ] GitHub Release に DMG をアップロード
- [ ] Product Hunt / Reddit / X に投稿

---

## 6. CLAUDE.md（このプロジェクト用）

プロジェクトルートに配置する。

```markdown
# ClaudeMD Viewer

macOS menu bar app to preview and switch CLAUDE.md files across projects.
Also fetches CLAUDE.md from GitHub repos via URL input.
Built with Swift/SwiftUI, distributed as free OSS (MIT) with tip jar.

## Tech Stack
- Swift 5.9+ / SwiftUI
- macOS 12+ (Monterey), Universal Binary (Apple Silicon + Intel)
- AppKit: NSStatusItem + NSPopover (menu bar)
- Carbon: RegisterEventHotKey (global shortcut Cmd+Shift+M)
- apple/swift-markdown: Markdown → AttributedString rendering
- URLSession: GitHub Raw Content API (no auth, 60 req/hr)
- UserDefaults: settings + GitHub bookmarks persistence

## Project Structure
- Views/ — SwiftUI views (popover, tabs, list, preview, settings, components)
- Models/ — Data models (Project, GitHubBookmark, AppSettings)
- ViewModels/ — State management for each view
- Services/ — Business logic (scanner, watcher, GitHub fetcher, markdown renderer)
- Utilities/ — Helpers (hotkey, shell, clipboard, date formatting)

## Build
- `chmod +x build.sh && ./build.sh`
- Output: `build/ClaudeMDViewer.app`
- DMG: `./create_dmg.sh`

## Design Principles
- Menu bar only — no Dock icon (LSUIElement = true)
- Lightweight: <5MB, minimal CPU/memory
- Privacy first: no analytics, no tracking, no network except GitHub raw content API and Stripe tip link
- Dark mode fixed (menu bar popover is always dark)
- Native macOS look and feel (no web views for core UI)
- All icons are stroke-based SVGs using currentColor

## Key Implementation Notes
- NSPopover for rich content (not NSMenu)
- FileManager.enumerator for directory scanning with skipDescendants optimization
- Token estimation: character_count / 4
- GitHub fetch: try main branch first, then master, error if both 404
- Editor launch: NSWorkspace.shared.open with specific app URL
- Terminal launch: AppleScript → Terminal.app → cd to project path
- Global shortcut: Carbon RegisterEventHotKey
- Two-step delete confirmation: trash icon → "Remove?" button → execute
- Preview header has both reload button (re-read file or re-fetch) and trash button
- Toast notifications auto-dismiss after 1.8 seconds

## Code Style
- MVVM architecture: View ↔ ViewModel ↔ Service
- @Published properties in ViewModels for SwiftUI reactivity
- async/await for all async operations
- Prefer computed properties over stored state where possible
- Keep Views thin — logic belongs in ViewModels or Services
```

---

## 7. 参考リンク

- [ClaudeUsageBar](https://github.com/Artzainnn/ClaudeUsageBar) — 同アプローチで成功した前例。Swift/SwiftUI メニューバーアプリ
- [ClaudeUsageBar Website](https://www.claudeusagebar.com) — ランディングページの参考
- [Anthropic: Using CLAUDE.md files](https://claude.com/blog/using-claude-md-files) — CLAUDE.md の公式ドキュメント
- [apple/swift-markdown](https://github.com/apple/swift-markdown) — Apple 公式 Markdown パーサー
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — リリース後の投稿先
- [GitHub Raw Content API](https://docs.github.com/en/rest/repos/contents) — CLAUDE.md 取得用
- [Stripe Payment Links](https://stripe.com/docs/payment-links) — チップ機能
