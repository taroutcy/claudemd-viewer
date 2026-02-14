# Icons and Assets Usage Guide

## 概要

ClaudeMD Viewerでは、SF Symbols（システムアイコン）を使用しています。
すべてのアイコンは`AppIcon`列挙型で定義され、一貫性のある使用が保証されています。

## ファイル構成

- `Utilities/AppIcons.swift` - アイコン定義
- `Utilities/AppColors.swift` - カラーパレット定義
- `ClaudeMDViewer/Assets.xcassets/MenuBarIcon.imageset/` - メニューバーアイコン

## アイコン一覧

### ナビゲーション
- `AppIcon.doc` - プロジェクト、ドキュメント
- `AppIcon.back` - 戻るボタン
- `AppIcon.search` - 検索

### GitHub
- `AppIcon.github` - GitHubタブ、ブックマーク
- `AppIcon.globe` - GitHubを開く

### アクション
- `AppIcon.copy` - コピー
- `AppIcon.check` - 成功、完了
- `AppIcon.edit` - 編集
- `AppIcon.terminal` - ターミナルで開く
- `AppIcon.folder` - Finderで開く
- `AppIcon.download` - ダウンロード
- `AppIcon.trash` - 削除

### システム
- `AppIcon.refresh` - リロード
- `AppIcon.settings` - 設定
- `AppIcon.warning` - 警告
- `AppIcon.pin` / `AppIcon.pinSlash` - ピン留め

## SwiftUIでの使用例

### 基本的な使用

```swift
// SF Symbolsを使用
Image(systemName: AppIcon.copy)
    .foregroundColor(.accent)

// ヘルパーメソッドを使用
AppIcon.systemImage(AppIcon.edit)
    .font(.system(size: 16))
```

### ボタンでの使用

```swift
Button(action: { /* ... */ }) {
    Label("Copy", systemImage: AppIcon.copy)
}

Button(action: { /* ... */ }) {
    Image(systemName: AppIcon.trash)
        .foregroundColor(.error)
}
```

### メニューバーアイコン

```swift
// AppDelegateで使用
if let icon = AppIcon.menuBarIcon() {
    statusItem.button?.image = icon
}
```

## カラーの使用例

```swift
// テキストカラー
Text("Hello")
    .foregroundColor(.textMain)

Text("Secondary")
    .foregroundColor(.textSecondary)

// 背景カラー
VStack {
    // content
}
.background(Color.appBackground)

// アクセントカラー
Button("Action") { /* ... */ }
    .foregroundColor(.accent)

// トークン数に応じた色
Text("\(tokens) tokens")
    .foregroundColor(Color.tokenColor(for: tokens))

// ピン留めグラデーション
RoundedRectangle(cornerRadius: 8)
    .fill(Color.pinGradient)
```

## カスタマイズ

### アイコンサイズ

```swift
Image(systemName: AppIcon.copy)
    .font(.system(size: 14, weight: .regular))

Image(systemName: AppIcon.settings)
    .imageScale(.large)
```

### カラー

```swift
Image(systemName: AppIcon.trash)
    .foregroundColor(.error)

Image(systemName: AppIcon.check)
    .foregroundColor(.success)
```

## 注意事項

- すべてのアイコンはSF Symbolsを使用しているため、macOS 11+が必要
- `currentColor`（SwiftUIでは`foregroundColor`）を使用してテーマに追従
- メニューバーアイコンは自動的にテンプレートモードで表示される
- 14-16pxのサイズを推奨（可読性のため）

## SF Symbols対応表

| 仕様書の名前 | SF Symbols名 | AppIcon定数 |
|------------|-------------|------------|
| doc | doc.text | AppIcon.doc |
| github | arrow.up.forward.circle | AppIcon.github |
| search | magnifyingglass | AppIcon.search |
| copy | doc.on.doc | AppIcon.copy |
| check | checkmark | AppIcon.check |
| edit | pencil | AppIcon.edit |
| terminal | terminal | AppIcon.terminal |
| folder | folder | AppIcon.folder |
| refresh | arrow.clockwise | AppIcon.refresh |
| globe | globe | AppIcon.globe |
| download | arrow.down.to.line | AppIcon.download |
| trash | trash | AppIcon.trash |
| settings | gearshape | AppIcon.settings |
| back | chevron.left | AppIcon.back |
