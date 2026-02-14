//
//  ProjectScanner.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation

/// プロジェクトディレクトリをスキャンしてCLAUDE.mdを含むプロジェクトを検出するサービス
actor ProjectScanner {

    /// プロジェクトをスキャン
    /// - Parameter settings: アプリケーション設定
    /// - Returns: 検出されたプロジェクトの配列（最終更新日でソート済み）
    func scanProjects(settings: AppSettings) async throws -> [Project] {
        var projects: [Project] = []

        // 設定から除外パターンを取得
        let excludes = settings.excludePatterns

        for folder in settings.scanFolders {
            // フォルダが存在するか確認
            guard FileManager.default.fileExists(atPath: folder.path) else {
                continue
            }

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
                if excludes.contains(url.lastPathComponent) {
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
                    let modDate = hasClaudeMd ? (try? FileManager.default.attributesOfItem(
                        atPath: claudeMd.path
                    )[.modificationDate] as? Date) : nil

                    // プロジェクト内の全.mdファイルを検出
                    let availableMdFiles = scanMarkdownFiles(in: url)

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
                        claudeMdContent: content,
                        availableMdFiles: availableMdFiles
                    ))

                    enumerator.skipDescendants() // プロジェクトルートを見つけたら子は不要
                }
            }
        }

        // 最終更新日でソート（新しい順）
        return projects.sorted { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }
    }

    /// プロジェクト名を取得（package.jsonのnameフィールドがあればそれを使用、なければディレクトリ名）
    /// - Parameter url: プロジェクトディレクトリのURL
    /// - Returns: プロジェクト名
    private func projectName(for url: URL) -> String {
        let packageJson = url.appendingPathComponent("package.json")
        if let data = try? Data(contentsOf: packageJson),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String {
            return name
        }
        return url.lastPathComponent
    }

    /// トークン数を推定（文字数 ÷ 4）
    /// - Parameter content: テキストコンテンツ
    /// - Returns: 推定トークン数
    private func estimateTokens(_ content: String?) -> Int {
        guard let content = content else { return 0 }
        return content.count / 4
    }

    /// ファイルが存在する場合にURLを返す
    /// - Parameter url: ファイルのURL
    /// - Returns: ファイルが存在すればURL、なければnil
    private func fileIfExists(_ url: URL) -> URL? {
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// プロジェクトディレクトリ内の全.mdファイルをスキャン
    /// - Parameter projectUrl: プロジェクトディレクトリのURL
    /// - Returns: .mdファイルのURL配列（CLAUDE.mdが最初、それ以外はアルファベット順）
    private func scanMarkdownFiles(in projectUrl: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: projectUrl,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var mdFiles: [URL] = []
        let excludeDirs = ["node_modules", ".git", "build", "dist", "target", ".next", ".cache"]

        for case let url as URL in enumerator {
            // 除外ディレクトリをスキップ
            if let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
               isDir,
               excludeDirs.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }

            // .mdファイルのみ収集
            if url.pathExtension == "md" {
                mdFiles.append(url)
            }
        }

        // CLAUDE.mdを最初に、それ以外はアルファベット順でソート
        return mdFiles.sorted { url1, url2 in
            let name1 = url1.lastPathComponent
            let name2 = url2.lastPathComponent

            if name1 == "CLAUDE.md" { return true }
            if name2 == "CLAUDE.md" { return false }

            return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
        }
    }
}
