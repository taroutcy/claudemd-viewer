//
//  ProjectListView.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI

/// ローカルプロジェクト一覧ビュー
struct ProjectListView: View {

    @EnvironmentObject private var viewModel: ProjectListViewModel
    @Binding var selectedProject: Project?
    @Binding var showSettings: Bool
    @Binding var showPreview: Bool

    private let settings: AppSettings

    /// ホバー中のプロジェクトID
    @State private var hoveredProjectId: UUID?

    /// 削除確認中のプロジェクトID
    @State private var deleteConfirmationId: UUID?

    // MARK: - Initialization

    init(
        selectedProject: Binding<Project?>,
        showSettings: Binding<Bool>,
        showPreview: Binding<Bool>,
        settings: AppSettings
    ) {
        self._selectedProject = selectedProject
        self._showSettings = showSettings
        self._showPreview = showPreview
        self.settings = settings
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            SearchBarView(searchText: $viewModel.searchText)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // プロジェクト一覧
            if viewModel.isScanning {
                // スキャン中のインジケーター
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning projects...")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredProjects.isEmpty {
                // プロジェクトが見つからない場合
                VStack(spacing: 12) {
                    Image(systemName: viewModel.searchText.isEmpty ? "folder" : "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(Color.textTertiary)

                    Text(viewModel.searchText.isEmpty ? "No projects found" : "No matching projects")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)

                    if viewModel.searchText.isEmpty {
                        Text("Add scan folders in Settings")
                            .font(.system(size: 11))
                            .foregroundColor(Color.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // プロジェクトリスト
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredProjects) { project in
                            projectRow(project)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }

            Divider()
                .background(Color.white.opacity(0.08))

            // フッター
            HStack(spacing: 12) {
                // プロジェクト数のサマリー
                Text("\(viewModel.projects.count) projects")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textSecondary)

                if viewModel.missingClaudeMdCount > 0 {
                    Text("·")
                        .foregroundColor(Color.textTertiary)

                    Text("\(viewModel.missingClaudeMdCount) missing")
                        .font(.system(size: 11))
                        .foregroundColor(Color.warning)
                }

                Spacer()

                // リフレッシュボタン
                Button(action: {
                    Task {
                        await viewModel.refreshProjects(settings: settings)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                        .rotationEffect(.degrees(viewModel.isScanning ? 360 : 0))
                        .animation(
                            viewModel.isScanning
                                ? Animation.linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: viewModel.isScanning
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isScanning)
                .help("Refresh projects")

                // 設定ボタン
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Settings")

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
        .task {
            // 初回スキャン
            if viewModel.projects.isEmpty {
                await viewModel.refreshProjects(settings: settings)
            }
            // 自動スキャンを開始
            viewModel.startAutoScan(settings: settings)
        }
        .onDisappear {
            // 自動スキャンを停止
            viewModel.stopAutoScan()
        }
    }

    // MARK: - Project Row

    private func projectRow(_ project: Project) -> some View {
        HStack(spacing: 12) {
            // ドキュメントアイコン or 警告マーク
            Image(systemName: project.claudeMdPath != nil ? "doc.text" : "exclamationmark.triangle")
                .font(.system(size: 16))
                .foregroundColor(project.claudeMdPath != nil ? Color.accent : Color.warning)
                .frame(width: 24, height: 24)

            // プロジェクト情報
            VStack(alignment: .leading, spacing: 4) {
                // プロジェクト名
                Text(project.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(project.claudeMdPath != nil ? Color.textMain : Color.textTertiary)
                    .lineLimit(1)

                // 最終更新日 + トークン数
                HStack(spacing: 6) {
                    if let lastModified = project.lastModified {
                        Text(RelativeDateFormatter.string(from: lastModified))
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }

                    if project.claudeMdPath != nil {
                        Text("·")
                            .foregroundColor(.textTertiary)

                        Text("~\(project.tokenEstimate)")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()

            // ピン留めアイコン
            if project.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.accent)
            }

            // トークン数
            if project.claudeMdPath != nil {
                Text("~\(project.tokenEstimate)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.tokenColor(for: project.tokenEstimate))
            }

            // ゴミ箱アイコン（ホバー時に表示）
            if hoveredProjectId == project.id {
                if deleteConfirmationId == project.id {
                    // 削除確認ボタン
                    Button(action: {
                        viewModel.removeProject(project)
                        deleteConfirmationId = nil
                        hoveredProjectId = nil
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
                        deleteConfirmationId = project.id
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
                    project.isPinned
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
                .fill(hoveredProjectId == project.id ? Color.white.opacity(0.03) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    project.isPinned
                        ? Color(hex: "#7c5cbf").opacity(0.3)
                        : Color.white.opacity(hoveredProjectId == project.id ? 0.08 : 0),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredProjectId = isHovered ? project.id : nil
                if !isHovered {
                    // ホバーを外したら削除確認もリセット
                    if deleteConfirmationId == project.id {
                        deleteConfirmationId = nil
                    }
                }
            }
        }
        .onTapGesture {
            // プレビュー画面へ遷移
            selectedProject = project
            showPreview = true
        }
        .contextMenu {
            Button(action: {
                viewModel.togglePin(for: project)
            }) {
                Label(
                    project.isPinned ? "Unpin" : "Pin to Top",
                    systemImage: project.isPinned ? "pin.slash" : "pin"
                )
            }

            if project.claudeMdPath != nil {
                Button(action: {
                    Task {
                        await viewModel.reloadClaudeMd(for: project)
                    }
                }) {
                    Label("Reload CLAUDE.md", systemImage: "arrow.clockwise")
                }
            }

            Button(action: {
                ShellHelper.openInFinder(project.path)
            }) {
                Label("Open in Finder", systemImage: "folder")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectListView(
        selectedProject: .constant(nil),
        showSettings: .constant(false),
        showPreview: .constant(false),
        settings: .default
    )
    .environmentObject(ProjectListViewModel())
    .frame(width: 400, height: 560)
}
