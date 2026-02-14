//
//  GitHubBookmark.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation

/// GitHubリポジトリのブックマークを表すモデル
struct GitHubBookmark: Identifiable, Codable, Hashable {
    /// ブックマークの一意識別子
    let id: UUID

    /// リポジトリ名
    var name: String

    /// リポジトリのオーナー名
    var owner: String

    /// リポジトリ名
    var repo: String

    /// リポジトリのURL
    var url: String

    /// スター数（取得できた場合）
    var stars: String?

    /// CLAUDE.mdを取得した日時
    var fetchedAt: Date

    /// 推定トークン数（文字数 ÷ 4）
    var tokenEstimate: Int

    /// ピン留めされているか
    var isPinned: Bool

    /// CLAUDE.mdの内容
    var claudeMdContent: String
}
