//
//  AppSettings.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation

/// アプリケーションの設定を表すモデル
struct AppSettings: Codable {
    /// スキャン対象のフォルダリスト
    var scanFolders: [URL]

    /// スキャンする深度（デフォルト: 3）
    var scanDepth: Int

    /// スキャン間隔（分単位、デフォルト: 10）
    var scanIntervalMinutes: Int

    /// 除外するディレクトリパターン
    var excludePatterns: [String]

    /// グローバルショートカット（デフォルト: "⌘⇧M"）
    var globalShortcut: String

    /// ログイン時に起動するか（デフォルト: true）
    var launchAtLogin: Bool

    /// Stripe Donation Link URL
    var stripeDonationUrl: String

    /// デフォルト設定を返す
    static var `default`: AppSettings {
        AppSettings(
            scanFolders: [],
            scanDepth: 3,
            scanIntervalMinutes: 10,
            excludePatterns: [
                "node_modules",
                ".git",
                "vendor",
                "venv",
                ".venv",
                "__pycache__",
                "build",
                "dist",
                ".next"
            ],
            globalShortcut: "⌘⇧M",
            launchAtLogin: true,
            stripeDonationUrl: "https://buymeacoffee.com/t.taro"
        )
    }
}
