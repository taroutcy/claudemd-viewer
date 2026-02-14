//
//  PopoverContentView.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI

/// ポップオーバーのルートビュー（タブ切り替え + プレビュー）
struct PopoverContentView: View {

    // MARK: - State

    @EnvironmentObject private var projectListViewModel: ProjectListViewModel
    @EnvironmentObject private var gitHubViewModel: GitHubViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel

    @State private var selectedTab: Tab = .myProjects
    @State private var selectedProject: Project?
    @State private var showSettings = false
    @State private var showPreview = false

    // MARK: - Tab Enum

    enum Tab {
        case myProjects
        case github
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // メインビューは常に存在（破棄されない）
            mainView
                .opacity(showSettings || showPreview ? 0 : 1)
                .offset(x: showSettings || showPreview ? -1000 : 0)
                .disabled(showSettings || showPreview)
                .animation(.easeInOut(duration: 0.25), value: showSettings)
                .animation(.easeInOut(duration: 0.25), value: showPreview)

            // 設定画面（オーバーレイ）
            if showSettings {
                SettingsView(onClose: {
                    showSettings = false
                })
                .environmentObject(settingsViewModel)
                .transition(.move(edge: .trailing))
            }

            // プレビュー画面（オーバーレイ）
            if showPreview {
                if let project = selectedProject {
                    ProjectPreviewView(
                        project: project,
                        onBack: {
                            showPreview = false
                            selectedProject = nil
                        },
                        onDelete: {
                            projectListViewModel.removeProject(project)
                            showPreview = false
                            selectedProject = nil
                        },
                        onReload: {
                            Task {
                                await projectListViewModel.reloadClaudeMd(for: project)
                            }
                        },
                        settings: settingsViewModel.settings
                    )
                    .environmentObject(projectListViewModel)
                    .transition(.move(edge: .trailing))
                } else if let bookmark = gitHubViewModel.selectedBookmark {
                    GitHubPreviewView(
                        bookmark: bookmark,
                        onBack: {
                            showPreview = false
                            gitHubViewModel.selectedBookmark = nil
                        },
                        onDelete: {
                            gitHubViewModel.removeBookmark(bookmark)
                            showPreview = false
                            gitHubViewModel.selectedBookmark = nil
                        },
                        onReload: {
                            Task {
                                await gitHubViewModel.reloadClaudeMd(for: bookmark)
                            }
                        }
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .frame(width: 550, height: 700)
        .background(Color.appBackground)
        .onChange(of: gitHubViewModel.selectedBookmark) { newBookmark in
            if newBookmark != nil {
                showPreview = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettings"))) { _ in
            showSettings = true
        }
    }

    // MARK: - Main View

    private var mainView: some View {
        VStack(spacing: 0) {
            // タブバー
            HStack(spacing: 0) {
                TabButton(
                    title: "My Projects",
                    isSelected: selectedTab == .myProjects,
                    action: { selectedTab = .myProjects }
                )
                TabButton(
                    title: "GitHub",
                    isSelected: selectedTab == .github,
                    action: { selectedTab = .github }
                )
            }
            .frame(height: 44)
            .background(Color.appBackground)

            Divider()
                .background(Color.white.opacity(0.08))

            // タブコンテンツ
            if selectedTab == .myProjects {
                ProjectListView(
                    selectedProject: $selectedProject,
                    showSettings: $showSettings,
                    showPreview: $showPreview,
                    settings: settingsViewModel.settings
                )
                .environmentObject(projectListViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GitHubListView(viewModel: gitHubViewModel, settings: settingsViewModel.settings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Tab Button Component

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color.accent : Color.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected
                        ? Color.accent.opacity(0.1)
                        : Color.clear
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .focusable(false)
    }
}

// MARK: - Project Preview View (Placeholder)

/// ローカルプロジェクトのプレビュー画面
private struct ProjectPreviewView: View {
    let project: Project
    let onBack: () -> Void
    let onDelete: () -> Void
    let onReload: () -> Void
    let settings: AppSettings

    @EnvironmentObject private var projectListViewModel: ProjectListViewModel

    @State private var selectedMdFile: URL?
    @State private var selectedMdContent: String?
    @State private var tokenCount: Int = 0
    @State private var isLoadingContent = false
    @State private var renderedContent: AttributedString?
    @State private var currentLoadTaskId: UUID?  // レースコンディション防止用
    @State private var refreshTrigger: Int = 0  // ピン留め状態の更新をトリガー
    private let markdownRenderer = MarkdownRenderer()  // インスタンス再利用

    // ViewModelから最新のプロジェクトを取得する計算プロパティ
    private var currentProject: Project {
        let _ = refreshTrigger  // 依存関係を作成
        return projectListViewModel.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textMain)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: onReload) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)

            // mdファイル選択UI（複数ファイルがある場合のみ表示）
            if currentProject.availableMdFiles.count > 1 {
                Divider()
                    .background(Color.white.opacity(0.08))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(currentProject.sortedMdFiles, id: \.self) { mdFile in
                            HStack(spacing: 6) {
                                // ピン留めボタン
                                Button(action: {
                                    toggleMdFilePin(mdFile)
                                }) {
                                    Image(systemName: currentProject.pinnedMdFiles.contains(mdFile) ? "pin.fill" : "pin")
                                        .font(.system(size: 10))
                                        .foregroundColor(
                                            currentProject.pinnedMdFiles.contains(mdFile)
                                                ? Color.accent
                                                : Color.textTertiary.opacity(0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())

                                // ファイル名ボタン
                                Button(action: {
                                    selectMdFile(mdFile)
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mdFile.lastPathComponent)
                                            .font(.system(size: 12, weight: selectedMdFile == mdFile ? .semibold : .regular))
                                            .foregroundColor(selectedMdFile == mdFile ? Color.accent : Color.textSecondary)

                                        // プロジェクトからの相対パス
                                        let relativePath = mdFile.path.replacingOccurrences(of: project.path.path + "/", with: "")
                                        if relativePath != mdFile.lastPathComponent {
                                            Text(relativePath.replacingOccurrences(of: "/" + mdFile.lastPathComponent, with: ""))
                                                .font(.system(size: 11))
                                                .foregroundColor(Color.textTertiary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoadingContent)
                                .help(mdFile.path)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        selectedMdFile == mdFile
                                            ? Color.accent.opacity(0.15)
                                            : currentProject.pinnedMdFiles.contains(mdFile)
                                                ? Color.accent.opacity(0.08)
                                                : Color.white.opacity(0.05)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        currentProject.pinnedMdFiles.contains(mdFile)
                                            ? Color.accent.opacity(0.3)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.appBackground)
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // コンテンツ
            ScrollView {
                if isLoadingContent {
                    // ローディングインジケーター
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else if let content = renderedContent {
                    Text(content)
                        .textSelection(.enabled)
                        .padding(16)
                } else if selectedMdContent == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(Color.textTertiary)

                        if project.availableMdFiles.isEmpty {
                            Text("No .md files found")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.textSecondary)
                            Text("This project was detected via \(project.hasClaudeDir ? ".claude directory" : "project markers")")
                                .font(.system(size: 11))
                                .foregroundColor(Color.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        } else {
                            Text("Failed to load markdown file")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.error)
                            Text("File exists but could not be read")
                                .font(.system(size: 11))
                                .foregroundColor(Color.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                }
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // トークンバー
            TokenBarView(tokenCount: tokenCount)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color.appBackground)
        .onAppear {
            // 初期表示時にCLAUDE.mdまたは最初のファイルを選択
            if let claudeMd = project.claudeMdPath, let content = project.claudeMdContent {
                selectedMdFile = claudeMd
                selectedMdContent = content
                tokenCount = project.tokenEstimate

                // 既存コンテンツをレンダリング
                Task {
                    let rendered = await markdownRenderer.render(content, fileURL: claudeMd)
                    await MainActor.run {
                        renderedContent = rendered
                    }
                }
            } else if let firstFile = project.availableMdFiles.first {
                selectMdFile(firstFile)
            }
        }
    }

    private func selectMdFile(_ file: URL) {
        selectedMdFile = file
        isLoadingContent = true

        // 新しいタスクIDを生成
        let taskId = UUID()
        currentLoadTaskId = taskId

        Task {
            do {
                // バックグラウンドでファイル読み込み
                let content = try await Task.detached {
                    try String(contentsOf: file, encoding: .utf8)
                }.value

                // このタスクが最新のリクエストかチェック
                let isLatest = await MainActor.run {
                    currentLoadTaskId == taskId
                }
                guard isLatest else {
                    return
                }

                // Markdownレンダリング（非同期）
                let rendered = await markdownRenderer.render(content, fileURL: file)

                // 最終チェックとUI更新
                await MainActor.run {
                    guard currentLoadTaskId == taskId else {
                        return
                    }

                    selectedMdContent = content
                    renderedContent = rendered
                    tokenCount = content.count / 4
                    isLoadingContent = false
                }
            } catch {
                await MainActor.run {
                    guard currentLoadTaskId == taskId else {
                        return
                    }

                    selectedMdContent = nil
                    renderedContent = nil
                    tokenCount = 0
                    isLoadingContent = false
                    print("⚠️ Failed to read \(file.path): \(error)")
                }
            }
        }
    }

    private func toggleMdFilePin(_ mdFile: URL) {
        projectListViewModel.toggleMdFilePin(for: currentProject, mdFile: mdFile)

        // ビューの更新をトリガー
        refreshTrigger += 1
    }
}

// MARK: - GitHub Preview View (Placeholder)

/// GitHubブックマークのプレビュー画面
private struct GitHubPreviewView: View {
    let bookmark: GitHubBookmark
    let onBack: () -> Void
    let onDelete: () -> Void
    let onReload: () -> Void

    // Markdownレンダラー（再利用）
    private let markdownRenderer = MarkdownRenderer()

    @State private var renderedContent: AttributedString?

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.accent)
                }
                .buttonStyle(.plain)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textMain)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text("\(bookmark.owner)/\(bookmark.repo)")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)

                        if let stars = bookmark.stars {
                            Text("·")
                                .foregroundColor(Color.textTertiary)
                            Text("⭐ \(stars)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                }

                Spacer()

                Button(action: onReload) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appBackground)

            Divider()
                .background(Color.white.opacity(0.08))

            // コンテンツ
            ScrollView {
                if let content = renderedContent {
                    Text(content)
                        .textSelection(.enabled)
                        .padding(16)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(32)
                }
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // トークンバー
            TokenBarView(tokenCount: bookmark.tokenEstimate)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color.appBackground)
        .onAppear {
            Task {
                let rendered = await markdownRenderer.render(
                    bookmark.claudeMdContent,
                    cacheKey: "github_\(bookmark.id.uuidString)"
                )
                await MainActor.run {
                    renderedContent = rendered
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PopoverContentView()
}
