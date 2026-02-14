//
//  SettingsView.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI
import AppKit

/// 設定画面
struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                headerView

                // スキャンフォルダ設定
                scanFoldersSection

                // スキャン深度設定
                scanDepthSection

                // スキャン間隔設定
                scanIntervalSection

                // グローバルショートカット設定
                globalShortcutSection

                // Launch at Login設定
                launchAtLoginSection

                // フッター
                footerView
            }
            .padding(20)
        }
        .background(Color(hex: "#1c1c20"))
        .toast(message: toastMessage, type: toastType, isShowing: $showToast)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // 戻るボタン
            Button(action: {
                onClose?() ?? dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: "#c4a7ff"))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()

            // タイトル
            Text("Settings")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#eeeeee"))

            Spacer()

            // リセットボタン
            Button(action: {
                viewModel.resetToDefaults()
                showToastMessage("Settings reset to defaults", type: .success)
            }) {
                Text("Reset")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#e8c87a"))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Scan Folders Section

    private var scanFoldersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan Folders")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#eeeeee"))

            VStack(spacing: 8) {
                ForEach(viewModel.settings.scanFolders, id: \.self) { folder in
                    scanFolderRow(folder)
                }
            }

            // 追加ボタン
            Button(action: {
                selectFolder()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                    Text("Add Folder")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: "#c4a7ff"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "#c4a7ff").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    private func scanFolderRow(_ folder: URL) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "folder")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#c4a7ff"))

            Text(folder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#eeeeee"))
                .lineLimit(1)

            Spacer()

            Button(action: {
                viewModel.removeScanFolder(folder)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#4a4a55"))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#161625"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Scan Depth Section

    private var scanDepthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scan Depth")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#eeeeee"))

                Spacer()

                Text("\(viewModel.settings.scanDepth)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#c4a7ff"))
            }

            Slider(
                value: Binding(
                    get: { Double(viewModel.settings.scanDepth) },
                    set: { viewModel.settings.scanDepth = Int($0) }
                ),
                in: 1...10,
                step: 1
            )
            .tint(Color(hex: "#c4a7ff"))

            Text("Number of directory levels to scan (1-10)")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#999999"))
        }
    }

    // MARK: - Scan Interval Section

    private var scanIntervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan Interval")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#eeeeee"))

            HStack(spacing: 8) {
                ForEach([5, 10, 30], id: \.self) { interval in
                    intervalButton(interval)
                }
            }
        }
    }

    private func intervalButton(_ interval: Int) -> some View {
        Button(action: {
            viewModel.settings.scanIntervalMinutes = interval
        }) {
            Text("\(interval) min")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(
                    viewModel.settings.scanIntervalMinutes == interval
                        ? Color(hex: "#eeeeee")
                        : Color(hex: "#999999")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            viewModel.settings.scanIntervalMinutes == interval
                                ? Color(hex: "#c4a7ff").opacity(0.2)
                                : Color.white.opacity(0.03)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            viewModel.settings.scanIntervalMinutes == interval
                                ? Color(hex: "#c4a7ff").opacity(0.5)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Global Shortcut Section

    private var globalShortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Shortcut")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#eeeeee"))

            HStack {
                Text(viewModel.settings.globalShortcut)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#eeeeee"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#161625"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                Spacer()
            }

            Text("Keyboard shortcut to toggle the popover")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#999999"))
        }
    }

    // MARK: - Launch at Login Section

    private var launchAtLoginSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Launch at Login")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#eeeeee"))

                Text("Start ClaudeMD Viewer when you log in")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#999999"))
            }

            Spacer()

            Toggle("", isOn: $viewModel.settings.launchAtLogin)
                .labelsHidden()
                .tint(Color(hex: "#c4a7ff"))
                .onChange(of: viewModel.settings.launchAtLogin) { _ in
                    viewModel.toggleLaunchAtLogin()
                }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.08))

            HStack(spacing: 16) {
                // About
                Button(action: {
                    showToastMessage("ClaudeMD Viewer v1.0", type: .info)
                }) {
                    Text("About")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Text("·")
                    .foregroundColor(Color(hex: "#4a4a55"))

                // GitHub
                Button(action: {
                    if let url = URL(string: "https://github.com/taroutcy/claudemd-viewer") {
                        NSWorkspace.shared.open(url)
                        showToastMessage("Opening GitHub...", type: .info)
                    }
                }) {
                    Text("GitHub")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Text("·")
                    .foregroundColor(Color(hex: "#4a4a55"))

                // Buy Dev a Coffee
                Button(action: {
                    viewModel.openDonationUrl()
                }) {
                    Text("☕ Buy Dev a Coffee")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#c4a7ff"))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            Text("Made with ❤️ for Claude Code users")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#4a4a55"))
        }
    }

    // MARK: - Helper Methods

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = "Select Folder"
        panel.message = "Choose a folder to scan for projects"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addScanFolder(url)
            showToastMessage("Folder added", type: .success)
        }
    }

    private func showToastMessage(_ message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}
