//
//  ProjectListViewModel.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation
import Combine

/// ローカルプロジェクト一覧の状態管理
@MainActor
class ProjectListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// プロジェクト一覧
    @Published var projects: [Project] = []

    /// スキャン中かどうか
    @Published var isScanning: Bool = false

    /// 検索テキスト
    @Published var searchText: String = ""

    /// 選択中のプロジェクト（プレビュー表示用）
    @Published var selectedProject: Project?

    /// トースト通知メッセージ
    @Published var toastMessage: String?

    // MARK: - Private Properties

    private let projectScanner: ProjectScanner
    private var scanTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// フィルタリングされたプロジェクト一覧
    var filteredProjects: [Project] {
        let filtered: [Project]

        if searchText.isEmpty {
            filtered = projects
        } else {
            let lowercased = searchText.lowercased()
            filtered = projects.filter { project in
                // プロジェクト名で検索
                if project.name.lowercased().contains(lowercased) {
                    return true
                }
                // CLAUDE.mdの内容で検索
                if let content = project.claudeMdContent,
                   content.lowercased().contains(lowercased) {
                    return true
                }
                return false
            }
        }

        // ピン留めされたプロジェクトを上部に表示
        let pinned = filtered.filter { $0.isPinned }.sorted { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }
        let unpinned = filtered.filter { !$0.isPinned }.sorted { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }

        return pinned + unpinned
    }

    /// CLAUDE.mdが存在しないプロジェクトの数
    var missingClaudeMdCount: Int {
        projects.filter { $0.claudeMdPath == nil }.count
    }

    // MARK: - Initialization

    init(projectScanner: ProjectScanner = ProjectScanner()) {
        self.projectScanner = projectScanner
        loadPinnedProjects()
        loadPinnedMdFiles()
    }

    // MARK: - Public Methods

    /// プロジェクトをリフレッシュ（スキャン）
    func refreshProjects(settings: AppSettings) async {
        isScanning = true
        toastMessage = "Scanning..."

        do {
            let scannedProjects = try await projectScanner.scanProjects(settings: settings)

            // ピン留め状態を復元
            let pinnedMdData = UserDefaults.standard.dictionary(forKey: "pinnedMdFiles") as? [String: [String]]

            self.projects = scannedProjects.map { scanned in
                var project = scanned
                if let pinned = projects.first(where: { $0.path == scanned.path }) {
                    // 既存プロジェクトのピン留め状態を復元
                    project.isPinned = pinned.isPinned
                    project.pinnedMdFiles = pinned.pinnedMdFiles
                } else if let pinnedMdData = pinnedMdData,
                          let pinnedPaths = pinnedMdData[scanned.path.path] {
                    // 新規プロジェクトの場合、UserDefaultsから復元
                    project.pinnedMdFiles = pinnedPaths.compactMap { URL(fileURLWithPath: $0) }
                }
                return project
            }

            savePinnedProjects()
            savePinnedMdFiles()

        } catch {
            toastMessage = "Scan failed: \(error.localizedDescription)"
        }

        isScanning = false

        // トーストを1.8秒後に消去
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.toastMessage = nil
        }
    }

    /// 自動スキャンタイマーを開始
    func startAutoScan(settings: AppSettings) {
        stopAutoScan()

        let interval = TimeInterval(settings.scanIntervalMinutes * 60)
        scanTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshProjects(settings: settings)
            }
        }
    }

    /// 自動スキャンタイマーを停止
    func stopAutoScan() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    /// プロジェクトのピン留めをトグル
    func togglePin(for project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isPinned.toggle()
        savePinnedProjects()
    }

    /// mdファイルのピン留めをトグル
    func toggleMdFilePin(for project: Project, mdFile: URL) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }

        if projects[index].pinnedMdFiles.contains(mdFile) {
            projects[index].pinnedMdFiles.removeAll { $0 == mdFile }
        } else {
            projects[index].pinnedMdFiles.append(mdFile)
        }

        savePinnedMdFiles()
    }

    /// プロジェクトを一覧から削除
    func removeProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        savePinnedProjects()
        toastMessage = "Removed from list"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.toastMessage = nil
        }
    }

    /// CLAUDE.mdをリロード
    func reloadClaudeMd(for project: Project) async {
        guard let claudeMdPath = project.claudeMdPath else { return }

        toastMessage = "Reloading..."

        do {
            let content = try String(contentsOf: claudeMdPath, encoding: .utf8)

            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index].claudeMdContent = content
                projects[index].tokenEstimate = content.count / 4

                // 最終更新日時を更新
                let attributes = try FileManager.default.attributesOfItem(atPath: claudeMdPath.path)
                projects[index].lastModified = attributes[FileAttributeKey.modificationDate] as? Date
            }

        } catch {
            toastMessage = "Reload failed: \(error.localizedDescription)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.toastMessage = nil
        }
    }

    // MARK: - Private Methods (UserDefaults Persistence)

    private func savePinnedProjects() {
        let pinnedPaths = projects.filter { $0.isPinned }.map { $0.path.path }
        UserDefaults.standard.set(pinnedPaths, forKey: "pinnedProjects")
    }

    private func loadPinnedProjects() {
        // ピン留め情報は次回スキャン時に復元される
        // ここでは何もしない（初期化時にプロジェクトが空のため）
    }

    /// ピン留めされたmdファイル情報を保存
    private func savePinnedMdFiles() {
        var pinnedMdData: [String: [String]] = [:]

        for project in projects {
            if !project.pinnedMdFiles.isEmpty {
                pinnedMdData[project.path.path] = project.pinnedMdFiles.map { $0.path }
            }
        }

        UserDefaults.standard.set(pinnedMdData, forKey: "pinnedMdFiles")
    }

    /// ピン留めされたmdファイル情報を読み込み
    private func loadPinnedMdFiles() {
        guard let pinnedMdData = UserDefaults.standard.dictionary(forKey: "pinnedMdFiles") as? [String: [String]] else { return }

        for index in projects.indices {
            let projectPath = projects[index].path.path
            if let pinnedPaths = pinnedMdData[projectPath] {
                projects[index].pinnedMdFiles = pinnedPaths.compactMap { URL(fileURLWithPath: $0) }
            }
        }
    }
}
