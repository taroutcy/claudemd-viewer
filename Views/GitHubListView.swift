import SwiftUI

/// GitHubタブのビュー
/// URL入力、ブックマーク一覧、検索機能を提供
struct GitHubListView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: GitHubViewModel

    private let settings: AppSettings

    /// ホバー中のブックマークID
    @State private var hoveredBookmarkId: UUID?

    /// 削除確認中のブックマークID
    @State private var deleteConfirmationId: UUID?

    // MARK: - Initialization

    init(viewModel: GitHubViewModel, settings: AppSettings) {
        self.viewModel = viewModel
        self.settings = settings
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // URL入力セクション
            urlInputSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // 検索バー
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // ブックマーク一覧
            if viewModel.filteredBookmarks.isEmpty {
                emptyStateView
            } else {
                bookmarkList
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // フッター
            footerView
        }
        .background(Color.appBackground)
        .overlay(
            // トースト通知
            Group {
                if let message = viewModel.toastMessage {
                    ToastView(
                        message: message,
                        type: .info,
                        isShowing: .constant(true)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
            , alignment: .bottom
        )
    }

    // MARK: - URL Input Section

    private var urlInputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // URL入力フィールド
                HStack(spacing: 8) {
                    Image(systemName: AppIcon.github)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)

                    TextField("e.g. https://github.com/vercel/next.js", text: $viewModel.urlInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(.textMain)
                        .onSubmit {
                            Task {
                                await viewModel.fetchGitHub()
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.codeBlockBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

                // Fetchボタン
                Button(action: {
                    Task {
                        await viewModel.fetchGitHub()
                    }
                }) {
                    Text("Fetch")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textMain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accent.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accent.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(viewModel.isFetching || viewModel.urlInput.isEmpty)
                .opacity(viewModel.isFetching || viewModel.urlInput.isEmpty ? 0.5 : 1.0)
            }
        }
    }

    // MARK: - Bookmark List

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.filteredBookmarks) { bookmark in
                    bookmarkRow(bookmark)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func bookmarkRow(_ bookmark: GitHubBookmark) -> some View {
        HStack(spacing: 12) {
            // GitHubアイコン
            Image(systemName: AppIcon.github)
                .font(.system(size: 16))
                .foregroundColor(.accent)
                .frame(width: 24, height: 24)

            // ブックマーク情報
            VStack(alignment: .leading, spacing: 4) {
                // リポジトリ名
                Text(bookmark.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textMain)

                // owner/repo + スター数
                HStack(spacing: 6) {
                    Text("\(bookmark.owner)/\(bookmark.repo)")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)

                    if let stars = bookmark.stars {
                        HStack(spacing: 2) {
                            Text("⭐")
                                .font(.system(size: 9))
                            Text(stars)
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                // 取得日時
                Text(RelativeDateFormatter.string(from: bookmark.fetchedAt))
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)
            }

            Spacer()

            // ピン留めアイコン
            if bookmark.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.accent)
            }

            // トークン数
            Text("~\(bookmark.tokenEstimate)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.tokenColor(for: bookmark.tokenEstimate))

            // ゴミ箱アイコン（ホバー時に表示）
            if hoveredBookmarkId == bookmark.id {
                if deleteConfirmationId == bookmark.id {
                    // 削除確認ボタン
                    Button(action: {
                        viewModel.removeBookmark(bookmark)
                        deleteConfirmationId = nil
                        hoveredBookmarkId = nil
                    }) {
                        Text("Remove?")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.error)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.error.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    // ゴミ箱アイコン
                    Button(action: {
                        deleteConfirmationId = bookmark.id
                    }) {
                        Image(systemName: AppIcon.trash)
                            .font(.system(size: 14))
                            .foregroundColor(.error)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    bookmark.isPinned
                        ? LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#7c5cbf").opacity(0.15),
                                Color(hex: "#5b3e9e").opacity(0.15)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hoveredBookmarkId == bookmark.id ? Color.white.opacity(0.03) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    bookmark.isPinned
                        ? Color(hex: "#7c5cbf").opacity(0.3)
                        : Color.white.opacity(hoveredBookmarkId == bookmark.id ? 0.08 : 0),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredBookmarkId = isHovered ? bookmark.id : nil
                if !isHovered {
                    // ホバーを外したら削除確認もリセット
                    if deleteConfirmationId == bookmark.id {
                        deleteConfirmationId = nil
                    }
                }
            }
        }
        .onTapGesture {
            // プレビュー画面へ遷移
            viewModel.selectedBookmark = bookmark
        }
        .contextMenu {
            Button(action: {
                viewModel.togglePin(for: bookmark)
            }) {
                Label(
                    bookmark.isPinned ? "Unpin" : "Pin to Top",
                    systemImage: bookmark.isPinned ? "pin.slash" : "pin"
                )
            }

            Button("Open in GitHub") {
                let urlString = "https://github.com/\(bookmark.owner)/\(bookmark.repo)"
                ShellHelper.openUrl(urlString)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: AppIcon.github)
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)

            Text("No GitHub bookmarks")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)

            Text("Enter a GitHub URL above to fetch CLAUDE.md")
                .font(.system(size: 12))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            // ブックマーク数
            Text("\(viewModel.bookmarks.count) bookmarks")
                .font(.system(size: 11))
                .foregroundColor(Color.textSecondary)

            Spacer()

            // チップボタン
            Button(action: {
                if let url = URL(string: settings.stripeDonationUrl) {
                    NSWorkspace.shared.open(url)
                    viewModel.toastMessage = "Opening Stripe... ☕"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        viewModel.toastMessage = nil
                    }
                }
            }) {
                Text("☕")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .help("Buy Dev a Coffee")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appBackground)
    }
}

// MARK: - Preview

#Preview {
    GitHubListView(viewModel: GitHubViewModel(), settings: .default)
        .frame(width: 400, height: 560)
}
