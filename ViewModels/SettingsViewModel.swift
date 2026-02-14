//
//  SettingsViewModel.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation
import AppKit
import Combine
import ServiceManagement

/// 設定の状態管理
@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// アプリケーション設定
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    /// 設定が変更されたかどうか
    @Published var hasUnsavedChanges: Bool = false

    /// トースト通知メッセージ
    @Published var toastMessage: String?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "appSettings"

    // MARK: - Initialization

    init() {
        // 保存された設定を読み込む、なければデフォルト値
        self.settings = Self.loadSettings() ?? .default

        // 設定の変更を監視
        $settings
            .dropFirst() // 初回の設定はスキップ
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// スキャンフォルダを追加
    func addScanFolder(_ url: URL) {
        if !settings.scanFolders.contains(url) {
            settings.scanFolders.append(url)
        }
    }

    /// スキャンフォルダを削除
    func removeScanFolder(_ url: URL) {
        settings.scanFolders.removeAll { $0 == url }
    }

    /// 除外パターンを追加
    func addExcludePattern(_ pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !settings.excludePatterns.contains(trimmed) {
            settings.excludePatterns.append(trimmed)
        }
    }

    /// 除外パターンを削除
    func removeExcludePattern(_ pattern: String) {
        settings.excludePatterns.removeAll { $0 == pattern }
    }

    /// 設定をデフォルトにリセット
    func resetToDefaults() {
        settings = .default
        hasUnsavedChanges = false
        toastMessage = "Settings reset to defaults"
        clearToastAfterDelay()
    }

    /// 設定を保存
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            hasUnsavedChanges = false
        }
    }

    /// 設定を読み込み
    func loadSettings() {
        if let loaded = Self.loadSettings() {
            settings = loaded
            hasUnsavedChanges = false
        }
    }

    /// Stripe Donation URLを開く
    func openDonationUrl() {
        if let url = URL(string: settings.stripeDonationUrl) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            toastMessage = "Opening Stripe... ☕"
            clearToastAfterDelay()
        }
    }

    /// Launch at Login設定を切り替え
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if settings.launchAtLogin {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("⚠️ Failed to toggle launch at login: \(error)")
                toastMessage = "Failed to update launch settings"
                clearToastAfterDelay()
            }
        } else {
            print("⚠️ Launch at login requires macOS 13.0 or later")
            toastMessage = "Launch at login requires macOS 13+"
            clearToastAfterDelay()
        }
    }

    // MARK: - Private Methods

    /// UserDefaultsから設定を読み込み
    private static func loadSettings() -> AppSettings? {
        if let data = UserDefaults.standard.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return nil
    }

    private func clearToastAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.toastMessage = nil
        }
    }
}

// MARK: - Validation Helpers

extension SettingsViewModel {

    /// スキャン深度が有効範囲内かチェック
    var isValidScanDepth: Bool {
        settings.scanDepth >= 1 && settings.scanDepth <= 10
    }

    /// スキャン間隔が有効範囲内かチェック
    var isValidScanInterval: Bool {
        settings.scanIntervalMinutes >= 5 && settings.scanIntervalMinutes <= 60
    }

    /// 少なくとも1つのスキャンフォルダが設定されているかチェック
    var hasAtLeastOneScanFolder: Bool {
        !settings.scanFolders.isEmpty
    }

    /// すべての設定が有効かチェック
    var isValid: Bool {
        isValidScanDepth && isValidScanInterval && hasAtLeastOneScanFolder
    }
}
