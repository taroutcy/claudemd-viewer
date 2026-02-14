import SwiftUI

/// アプリケーション全体で使用するアイコンの定義
/// SF Symbolsを使用してシステムとの統合を最適化
enum AppIcon {

    // MARK: - Menu Bar & Project Icons

    /// プロジェクトアイコン、メニューバー用
    /// 角丸矩形 + 3本の横線を表現
    static let doc = "doc.text"

    // MARK: - Tab & Navigation Icons

    /// GitHubタブ、ブックマークアイコン
    static let github = "arrow.up.forward.circle"

    /// 検索バー
    static let search = "magnifyingglass"

    /// 戻るボタン
    static let back = "chevron.left"

    // MARK: - Action Icons

    /// コピーボタン
    static let copy = "doc.on.doc"

    /// コピー成功
    static let check = "checkmark"

    /// エディタで開く
    static let edit = "pencil"

    /// ターミナルで開く
    static let terminal = "terminal"

    /// Finderで開く
    static let folder = "folder"

    /// リロード / リフレッシュ
    static let refresh = "arrow.clockwise"

    /// GitHubを開く（ブラウザ）
    static let globe = "globe"

    /// .mdを保存
    static let download = "arrow.down.to.line"

    /// 削除
    static let trash = "trash"

    /// 設定
    static let settings = "gearshape"

    // MARK: - Status Icons

    /// 警告（CLAUDE.mdがない場合）
    static let warning = "exclamationmark.triangle"

    /// ピン留め
    static let pin = "pin.fill"

    /// ピン解除
    static let pinSlash = "pin.slash"

    // MARK: - Helper Methods

    /// システムイメージを取得
    /// - Parameter name: SF Symbolsの名前
    /// - Returns: Imageインスタンス
    static func systemImage(_ name: String) -> Image {
        Image(systemName: name)
    }

    /// メニューバー用のテンプレートイメージを作成
    /// - Returns: NSImageインスタンス（template mode）
    static func menuBarIcon() -> NSImage? {
        let config = NSImage.SymbolConfiguration(
            pointSize: 16,
            weight: .regular,
            scale: .medium
        )
        let image = NSImage(
            systemSymbolName: doc,
            accessibilityDescription: "ClaudeMD Viewer"
        )
        image?.isTemplate = true
        return image?.withSymbolConfiguration(config)
    }
}

// MARK: - SwiftUI Image Extensions

extension Image {
    /// AppIconから直接Imageを生成
    /// - Parameter icon: アイコン名
    /// - Returns: SF SymbolsのImage
    static func appIcon(_ iconName: String) -> Image {
        Image(systemName: iconName)
    }
}
