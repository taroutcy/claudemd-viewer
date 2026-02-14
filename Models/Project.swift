//
//  Project.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation

/// ローカルプロジェクトを表すモデル
struct Project: Identifiable, Codable, Hashable {
    /// プロジェクトの一意識別子
    let id: UUID

    /// プロジェクト名（ディレクトリ名またはpackage.jsonのname）
    var name: String

    /// プロジェクトのディレクトリパス
    var path: URL

    /// CLAUDE.mdファイルのパス（存在する場合）
    var claudeMdPath: URL?

    /// CLAUDE.local.mdファイルのパス（存在する場合）
    var localMdPath: URL?

    /// CLAUDE.mdの最終更新日時
    var lastModified: Date?

    /// 推定トークン数（文字数 ÷ 4）
    var tokenEstimate: Int

    /// .claudeディレクトリが存在するか
    var hasClaudeDir: Bool

    /// ピン留めされているか
    var isPinned: Bool

    /// CLAUDE.mdの内容（キャッシュ用）
    var claudeMdContent: String?

    /// プロジェクト内で利用可能な全.mdファイル
    var availableMdFiles: [URL]

    /// ピン留めされた.mdファイルのパス
    var pinnedMdFiles: [URL] = []

    /// ピン留めされたmdファイルと未ピン留めファイルをソートして返す
    var sortedMdFiles: [URL] {
        let pinned = availableMdFiles.filter { pinnedMdFiles.contains($0) }
        let unpinned = availableMdFiles.filter { !pinnedMdFiles.contains($0) }
        return pinned + unpinned
    }
}
