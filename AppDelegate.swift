//
//  AppDelegate.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Cocoa
import SwiftUI

/// アプリケーションのメインデリゲート
/// メニューバーアイコンとポップオーバーを管理
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// メニューバーのステータスアイテム
    var statusItem: NSStatusItem?

    /// ポップオーバーウィンドウ
    var popover: NSPopover?

    /// グローバルホットキーマネージャー
    private var hotKeyManager: HotKeyManager?

    /// 外側クリック検出用のイベントモニター
    private var eventMonitor: Any?

    /// プロジェクト一覧ViewModel（永続化）
    let projectListViewModel = ProjectListViewModel()

    /// GitHubブックマークViewModel（永続化）
    let gitHubViewModel = GitHubViewModel()

    /// 設定ViewModel（永続化）
    let settingsViewModel = SettingsViewModel()

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupPopover()
        setupHotKey()
    }

    deinit {
        // NotificationCenterのobserverを解除
        NotificationCenter.default.removeObserver(self)
        // イベントモニターを解除
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup Methods

    /// メニューバーアイテムをセットアップ
    private func setupMenuBar() {
        // NSStatusItemを作成（可変幅）
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // メニューバーアイコンを設定（カスタムアイコン）
        button.image = NSImage(named: "MenuBarIcon")

        // アイコンをテンプレート画像として設定（ダークモード対応）
        button.image?.isTemplate = true

        // 左クリックと右クリックの両方を検出
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(statusBarButtonClicked)
        button.target = self

        // 右クリックメニューを作成（まだ割り当てない）
        setupMenu()
    }

    /// 右クリックメニューをセットアップ
    private var contextMenu: NSMenu?

    private func setupMenu() {
        let menu = NSMenu()

        // Preferences...メニュー項目
        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        // セパレータ
        menu.addItem(NSMenuItem.separator())

        // Quitメニュー項目
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // メニューを保持するが、statusItemには割り当てない
        self.contextMenu = menu
    }

    /// ポップオーバーをセットアップ
    private func setupPopover() {
        popover = NSPopover()

        // ポップオーバーの初期サイズを設定（Medium: 幅550px、高さ700px）
        popover?.contentSize = NSSize(width: 550, height: 700)

        // semitransient behavior（より柔軟なイベント処理）
        // transientだとcontextMenu後にkey window状態が復帰しないため変更
        popover?.behavior = .semitransient

        // アニメーションを有効化（イベント処理の改善）
        popover?.animates = true

        // デリゲートを設定
        popover?.delegate = self

        // SwiftUIのPopoverContentViewをNSHostingControllerで埋め込み
        // ViewModelを@EnvironmentObjectとして注入
        let contentView = PopoverContentView()
            .environmentObject(projectListViewModel)
            .environmentObject(gitHubViewModel)
            .environmentObject(settingsViewModel)

        let hostingController = NSHostingController(rootView: contentView)

        // ビューの制約を設定
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // コンテンツサイズの優先度を設定
        hostingController.view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        hostingController.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        hostingController.view.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        popover?.contentViewController = hostingController

        // contextMenu終了通知を監視（重要: 右クリックメニュー後のポップオーバー再アクティブ化）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuDidEndTracking),
            name: NSMenu.didEndTrackingNotification,
            object: nil
        )
    }

    /// メニュー（contextMenu含む）が閉じられた時の処理
    @objc private func menuDidEndTracking(_ notification: Notification) {
        // ポップオーバーが開いている場合のみ処理
        guard let popover = popover, popover.isShown else { return }

        // 少し遅延させてポップオーバーをkey windowに復帰
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self, let popover = self.popover, popover.isShown else { return }

            // ポップオーバーのウィンドウを再アクティブ化
            if let popoverWindow = popover.contentViewController?.view.window {
                popoverWindow.makeKey()
                // アプリケーションもアクティブにする
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    /// グローバルホットキー（Cmd+Shift+M）をセットアップ
    private func setupHotKey() {
        hotKeyManager = HotKeyManager()
        hotKeyManager?.register { [weak self] in
            self?.togglePopover()
        }
    }

    // MARK: - Actions

    /// ステータスバーボタンのクリックを処理
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        // 右クリックまたはControlキー押下時はメニューを表示
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            guard let menu = contextMenu else { return }

            // ポップオーバーが開いている場合は閉じる
            if popover?.isShown == true {
                popover?.performClose(nil)
            }

            // 一時的にメニューを設定
            statusItem?.menu = menu

            // メニューを表示
            statusItem?.button?.performClick(nil)

            // メニュー表示後、即座に解除（次のイベントループで）
            DispatchQueue.main.async { [weak self] in
                self?.statusItem?.menu = nil
            }
        } else {
            // 左クリックは通常のトグル動作
            togglePopover()
        }
    }

    /// ポップオーバーの表示/非表示を切り替え
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        guard let popover = popover else { return }

        if popover.isShown {
            // ポップオーバーが表示されている場合は閉じる
            popover.performClose(nil)
            stopMonitoringOutsideClicks()
        } else {
            // ポップオーバーを表示
            // メニューバーアイコンの下側（minY）に表示
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )

            // ポップオーバーをアクティブにする
            NSApp.activate(ignoringOtherApps: true)

            // 外側クリック検出を開始
            startMonitoringOutsideClicks()
        }
    }

    // MARK: - Outside Click Monitoring

    /// ポップオーバー外側のクリックを監視開始
    private func startMonitoringOutsideClicks() {
        // 既存のモニターがあれば停止
        stopMonitoringOutsideClicks()

        // グローバルマウスダウンイベントを監視
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self,
                  let popover = self.popover,
                  popover.isShown else { return }

            // クリック位置を取得（スクリーン座標）
            let screenClickLocation = NSEvent.mouseLocation

            // ポップオーバーのフレームと比較
            if let popoverWindow = popover.contentViewController?.view.window {
                let popoverFrame = popoverWindow.frame

                // クリック位置がポップオーバーの外側の場合は閉じる
                if !popoverFrame.contains(screenClickLocation) {
                    popover.performClose(nil)
                    self.stopMonitoringOutsideClicks()
                }
            }
        }
    }

    /// ポップオーバー外側のクリック監視を停止
    private func stopMonitoringOutsideClicks() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// 設定画面を開く
    @objc func openPreferences() {
        // ポップオーバーを表示
        if popover?.isShown == false {
            togglePopover()
        }

        // 設定画面を開く通知を送信
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
        }
    }

    /// アプリケーションを終了
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    /// ポップオーバーをデタッチ可能にするかどうか
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return false
    }

    /// ポップオーバーが閉じられるかどうか
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        // semitransient behaviorでは外側クリックで閉じる
        // ポップオーバー内のボタンクリックでは閉じない
        return true
    }

    /// ポップオーバーのデタッチ可否を制御
    func popover(_ popover: NSPopover, willShow notification: Notification) {
        // ポップオーバーウィンドウの追加設定
        if let window = popover.contentViewController?.view.window {
            // マウスイベントを確実に受け取る
            window.acceptsMouseMovedEvents = true
            // 最初のマウスクリックを受け取る
            window.ignoresMouseEvents = false
        }
    }

    /// ポップオーバーが表示された時の処理
    func popoverDidShow(_ notification: Notification) {
        // ポップオーバーのウィンドウ設定を最適化
        guard let window = popover?.contentViewController?.view.window else { return }

        // 最初のマウスクリックを受け取る（外側クリック検知の改善）
        window.acceptsMouseMovedEvents = true

        // key windowとして設定
        window.makeKey()

        // 外側クリック検出を開始
        startMonitoringOutsideClicks()
    }

    /// ポップオーバーが閉じられた時の処理
    func popoverDidClose(_ notification: Notification) {
        // 外側クリック検出を停止
        stopMonitoringOutsideClicks()
    }
}
