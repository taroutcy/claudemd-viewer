//
//  PreviewView.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI

/// CLAUDE.mdのプレビュー画面
/// ローカルプロジェクトまたはGitHubブックマークの詳細を表示
struct PreviewView: View {
    // MARK: - Properties
    
    /// プレビュー対象のタイプ
    enum PreviewType {
        case localProject(Project)
        case githubBookmark(GitHubBookmark)
    }
    
    let previewType: PreviewType
    let onBack: () -> Void
    let onDelete: () -> Void
    let onReload: () -> Void
    
    @State private var settings: AppSettings = .default
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var copyButtonIcon: String = "doc.on.doc"
    @State private var renderedContent: AttributedString?

    // Markdownレンダラー（再利用）
    private let markdownRenderer = MarkdownRenderer()
    
    // MARK: - Computed Properties
    
    private var title: String {
        switch previewType {
        case .localProject(let project):
            return project.name
        case .githubBookmark(let bookmark):
            return bookmark.name
        }
    }
    
    private var subtitle: String? {
        switch previewType {
        case .localProject:
            return nil
        case .githubBookmark(let bookmark):
            if let stars = bookmark.stars {
                return "\(bookmark.owner)/\(bookmark.repo) · ⭐ \(stars)"
            } else {
                return "\(bookmark.owner)/\(bookmark.repo)"
            }
        }
    }
    
    private var content: String {
        switch previewType {
        case .localProject(let project):
            return project.claudeMdContent ?? ""
        case .githubBookmark(let bookmark):
            return bookmark.claudeMdContent
        }
    }
    
    private var tokenCount: Int {
        switch previewType {
        case .localProject(let project):
            return project.tokenEstimate
        case .githubBookmark(let bookmark):
            return bookmark.tokenEstimate
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // コンテンツ（スクロール可能）
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if content.isEmpty {
                        emptyContentView
                    } else if let rendered = renderedContent {
                        // MarkdownRendererでレンダリング
                        Text(rendered)
                            .textSelection(.enabled)
                            .padding(16)
                    } else {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(32)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // トークンバー
            TokenBarView(tokenCount: tokenCount)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // アクションボタン
            actionButtonsView
                .padding(12)
        }
        .background(Color(hex: "#1c1c20"))
        .overlay(
            // トースト通知
            toastOverlay,
            alignment: .bottom
        )
        .onAppear {
            loadMarkdown()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // 戻るボタン
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#eeeeee"))
            }
            .buttonStyle(.plain)
            
            // タイトルとサブタイトル
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#eeeeee"))
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#999999"))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // リロードボタン
            Button(action: handleReload) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#eeeeee"))
            }
            .buttonStyle(.plain)
            
            // 削除ボタン
            Button(action: handleDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#e06060"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Empty Content View
    
    private var emptyContentView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#4a4a55"))
            
            Text("No content available")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Load Markdown

    private func loadMarkdown() {
        Task {
            let rendered: AttributedString
            switch previewType {
            case .localProject(let project):
                rendered = await markdownRenderer.render(
                    content,
                    fileURL: project.claudeMdPath
                )
            case .githubBookmark(let bookmark):
                rendered = await markdownRenderer.render(
                    content,
                    cacheKey: "github_\(bookmark.id.uuidString)"
                )
            }

            await MainActor.run {
                renderedContent = rendered
            }
        }
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            switch previewType {
            case .localProject(let project):
                localProjectButtons(project: project)
            case .githubBookmark(let bookmark):
                githubBookmarkButtons(bookmark: bookmark)
            }
        }
    }
    
    // ローカルプロジェクト用のボタン
    private func localProjectButtons(project: Project) -> some View {
        Group {
            // Copyボタン
            ActionButtonView(
                icon: copyButtonIcon,
                label: "Copy",
                action: handleCopy
            )
            
            // Editボタン
            ActionButtonView(
                icon: "pencil",
                label: "Edit",
                action: {
                    handleEdit(project: project)
                }
            )
            
            // Terminalボタン
            ActionButtonView(
                icon: "terminal",
                label: "Term",
                action: {
                    handleTerminal(project: project)
                }
            )
            
            // Finderボタン
            ActionButtonView(
                icon: "folder",
                label: "Find",
                action: {
                    handleFinder(project: project)
                }
            )
        }
    }
    
    // GitHubブックマーク用のボタン
    private func githubBookmarkButtons(bookmark: GitHubBookmark) -> some View {
        Group {
            // Copyボタン
            ActionButtonView(
                icon: copyButtonIcon,
                label: "Copy",
                action: handleCopy
            )
            
            // GitHubボタン
            ActionButtonView(
                icon: "globe",
                label: "GH",
                action: {
                    handleGitHub(bookmark: bookmark)
                }
            )
            
            // Save .mdボタン
            ActionButtonView(
                icon: "arrow.down.doc",
                label: "Save",
                action: {
                    handleSave(bookmark: bookmark)
                }
            )
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleCopy() {
        if ClipboardHelper.copy(content) {
            copyButtonIcon = "checkmark"
            showToastMessage("Copied to clipboard!")
            
            // 1秒後にアイコンを元に戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                copyButtonIcon = "doc.on.doc"
            }
        }
    }
    
    private func handleEdit(project: Project) {
        guard let claudeMdPath = project.claudeMdPath else { return }
        ShellHelper.openInEditor(claudeMdPath)
        showToastMessage("Opening in editor...")
    }
    
    private func handleTerminal(project: Project) {
        ShellHelper.openTerminal(at: project.path)
        showToastMessage("Opening Terminal...")
    }
    
    private func handleFinder(project: Project) {
        ShellHelper.openInFinder(project.path)
        showToastMessage("Opening Finder...")
    }
    
    private func handleGitHub(bookmark: GitHubBookmark) {
        ShellHelper.openUrl(bookmark.url)
        showToastMessage("Opening GitHub...")
    }
    
    private func handleSave(bookmark: GitHubBookmark) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "CLAUDE.md"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try bookmark.claudeMdContent.write(to: url, atomically: true, encoding: .utf8)
                    showToastMessage("Saved to \(url.lastPathComponent)")
                } catch {
                    showToastMessage("Failed to save file")
                }
            }
        }
    }
    
    private func handleReload() {
        showToastMessage("Reloading...")
        onReload()
    }
    
    private func handleDelete() {
        onDelete()
    }
    
    // MARK: - Toast
    
    private var toastOverlay: some View {
        Group {
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: .info,
                    isShowing: $showToast
                )
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(.easeOut(duration: 0.2)) {
            showToast = true
        }
        
        // 1.8秒後に自動消去
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.2)) {
                showToast = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleProject = Project(
        id: UUID(),
        name: "SampleProject",
        path: URL(fileURLWithPath: "/Users/test/Projects/SampleProject"),
        claudeMdPath: URL(fileURLWithPath: "/Users/test/Projects/SampleProject/CLAUDE.md"),
        localMdPath: nil,
        lastModified: Date(),
        tokenEstimate: 1240,
        hasClaudeDir: true,
        isPinned: false,
        claudeMdContent: """
# Sample Project

## Overview
This is a sample CLAUDE.md file for preview.

## Features
- Feature 1
- Feature 2
- Feature 3

## Code Example
```swift
func hello() {
    print("Hello, World!")
}
```

This project uses `SwiftUI` for the UI layer.
""",
        availableMdFiles: []
    )
    
    return PreviewView(
        previewType: .localProject(sampleProject),
        onBack: {},
        onDelete: {},
        onReload: {}
    )
    .frame(width: 400, height: 600)
}
