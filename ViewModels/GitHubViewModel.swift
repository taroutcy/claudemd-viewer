//
//  GitHubViewModel.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation
import Combine

/// GitHub機能の状態管理
@MainActor
class GitHubViewModel: ObservableObject {

    // MARK: - Published Properties

    /// GitHubブックマーク一覧
    @Published var bookmarks: [GitHubBookmark] = []

    /// 検索テキスト
    @Published var searchText: String = ""

    /// URL入力テキスト
    @Published var urlInput: String = ""

    /// フェッチ中かどうか
    @Published var isFetching: Bool = false

    /// 選択中のブックマーク（プレビュー表示用）
    @Published var selectedBookmark: GitHubBookmark?

    /// トースト通知メッセージ
    @Published var toastMessage: String?

    /// レート制限情報
    @Published var rateLimitInfo: GitHubFetcher.RateLimitInfo?

    // MARK: - Private Properties

    private let gitHubFetcher: GitHubFetcher
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// フィルタリングされたブックマーク一覧
    var filteredBookmarks: [GitHubBookmark] {
        let filtered: [GitHubBookmark]

        if searchText.isEmpty {
            filtered = bookmarks
        } else {
            let lowercased = searchText.lowercased()
            filtered = bookmarks.filter { bookmark in
                // リポジトリ名で検索
                if bookmark.name.lowercased().contains(lowercased) {
                    return true
                }
                // owner/repo で検索
                if "\(bookmark.owner)/\(bookmark.repo)".lowercased().contains(lowercased) {
                    return true
                }
                // CLAUDE.mdの内容で検索
                if bookmark.claudeMdContent.lowercased().contains(lowercased) {
                    return true
                }
                return false
            }
        }

        // ピン留めされたブックマークを上部に表示
        let pinned = filtered.filter { $0.isPinned }.sorted { $0.fetchedAt > $1.fetchedAt }
        let unpinned = filtered.filter { !$0.isPinned }.sorted { $0.fetchedAt > $1.fetchedAt }

        return pinned + unpinned
    }

    // MARK: - Initialization

    init(gitHubFetcher: GitHubFetcher = GitHubFetcher()) {
        self.gitHubFetcher = gitHubFetcher
        loadBookmarks()
        loadPinnedBookmarks()
    }

    // MARK: - Public Methods

    /// GitHub URLからCLAUDE.mdを取得
    func fetchGitHub() async {
        guard !urlInput.isEmpty else {
            toastMessage = "Please enter a GitHub URL"
            clearToastAfterDelay()
            return
        }

        // URLをパース
        guard let (owner, repo) = gitHubFetcher.parseGitHubUrl(urlInput) else {
            toastMessage = "Invalid GitHub URL"
            clearToastAfterDelay()
            return
        }

        // 既に存在するブックマークか確認
        if bookmarks.contains(where: { $0.owner == owner && $0.repo == repo }) {
            toastMessage = "Already bookmarked"
            clearToastAfterDelay()
            return
        }

        isFetching = true
        toastMessage = "Fetching CLAUDE.md..."

        do {
            // CLAUDE.mdを取得
            let content = try await gitHubFetcher.fetchClaudeMd(owner: owner, repo: repo)

            // スター数を取得（オプショナル）
            var stars: String?
            do {
                stars = try await gitHubFetcher.fetchRepoInfo(owner: owner, repo: repo)
            } catch {
                // スター数の取得に失敗してもエラーにしない
                stars = nil
            }

            // ブックマークを作成
            let bookmark = GitHubBookmark(
                id: UUID(),
                name: repo,
                owner: owner,
                repo: repo,
                url: "https://github.com/\(owner)/\(repo)",
                stars: stars,
                fetchedAt: Date(),
                tokenEstimate: content.count / 4,
                isPinned: false,
                claudeMdContent: content
            )

            // ブックマークに追加
            bookmarks.insert(bookmark, at: 0)
            saveBookmarks()

            // レート制限情報を更新
            rateLimitInfo = gitHubFetcher.rateLimitInfo

            // URL入力をクリア
            urlInput = ""

            toastMessage = "CLAUDE.md fetched ✓"

        } catch GitHubFetcher.FetchError.notFound {
            toastMessage = "CLAUDE.md not found in this repo"
        } catch {
            toastMessage = "Fetch failed: \(error.localizedDescription)"
        }

        isFetching = false
        clearToastAfterDelay()
    }

    /// ブックマークを削除
    func removeBookmark(_ bookmark: GitHubBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
        toastMessage = "Removed from bookmarks"
        clearToastAfterDelay()
    }

    /// CLAUDE.mdを再取得
    func reloadClaudeMd(for bookmark: GitHubBookmark) async {
        isFetching = true
        toastMessage = "Reloading..."

        do {
            let content = try await gitHubFetcher.fetchClaudeMd(owner: bookmark.owner, repo: bookmark.repo)

            // スター数を取得（オプショナル）
            var stars: String?
            do {
                stars = try await gitHubFetcher.fetchRepoInfo(owner: bookmark.owner, repo: bookmark.repo)
            } catch {
                stars = bookmark.stars // 既存の値を保持
            }

            if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                bookmarks[index].claudeMdContent = content
                bookmarks[index].tokenEstimate = content.count / 4
                bookmarks[index].stars = stars
                bookmarks[index].fetchedAt = Date()
            }

            saveBookmarks()

            // レート制限情報を更新
            rateLimitInfo = gitHubFetcher.rateLimitInfo

            toastMessage = "CLAUDE.md fetched ✓"

        } catch GitHubFetcher.FetchError.notFound {
            toastMessage = "CLAUDE.md not found in this repo"
        } catch {
            toastMessage = "Reload failed: \(error.localizedDescription)"
        }

        isFetching = false
        clearToastAfterDelay()
    }

    /// ブックマークのピン留めをトグル
    func togglePin(for bookmark: GitHubBookmark) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
        bookmarks[index].isPinned.toggle()
        savePinnedBookmarks()
    }

    // MARK: - Private Methods (UserDefaults Persistence)

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "githubBookmarks")
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "githubBookmarks"),
           let decoded = try? JSONDecoder().decode([GitHubBookmark].self, from: data) {
            bookmarks = decoded
        }
    }

    /// ピン留めされたブックマーク情報を保存
    private func savePinnedBookmarks() {
        let pinnedIds = bookmarks.filter { $0.isPinned }.map { $0.id.uuidString }
        UserDefaults.standard.set(pinnedIds, forKey: "pinnedGitHubBookmarks")
    }

    /// ピン留めされたブックマーク情報を読み込み
    private func loadPinnedBookmarks() {
        guard let pinnedIds = UserDefaults.standard.array(forKey: "pinnedGitHubBookmarks") as? [String] else { return }

        for index in bookmarks.indices {
            if pinnedIds.contains(bookmarks[index].id.uuidString) {
                bookmarks[index].isPinned = true
            }
        }
    }

    private func clearToastAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.toastMessage = nil
        }
    }
}
