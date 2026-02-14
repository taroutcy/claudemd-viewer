import Foundation
import Carbon

/// グローバルホットキーを管理するクラス
/// Carbon APIを使用してCmd+Shift+Mを登録し、ポップオーバーの表示/非表示をトリガーする
final class HotKeyManager {

    // MARK: - Properties

    /// ホットキーの参照（UnregisterEventHotKeyで使用）
    private var hotKeyRef: EventHotKeyRef?

    /// ホットキーID
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D444D44), id: 1) // 'MDMD'

    /// ポップオーバーの表示/非表示をトリガーするクロージャー
    private var onToggle: (() -> Void)?

    /// イベントハンドラの参照（メモリ管理用）
    private var eventHandler: EventHandlerRef?

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// グローバルホットキーを登録
    /// - Parameter onToggle: ホットキーが押された時に呼ばれるクロージャー
    /// - Returns: 登録に成功した場合true、失敗した場合false
    @discardableResult
    func register(onToggle: @escaping () -> Void) -> Bool {
        // 既に登録されている場合は一度解除
        unregister()

        self.onToggle = onToggle

        // イベントハンドラをインストール
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                // ユーザーデータからHotKeyManagerインスタンスを復元
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                // イベントIDを取得
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                // イベントIDが一致する場合、トグルクロージャーを呼び出す
                if result == noErr && hotKeyID.id == manager.hotKeyID.id {
                    DispatchQueue.main.async {
                        manager.onToggle?()
                    }
                    return noErr
                }

                return OSStatus(eventNotHandledErr)
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            print("HotKeyManager: Failed to install event handler (status: \(status))")
            return false
        }

        // ホットキーを登録（Cmd+Shift+M）
        // cmdKey = 256, shiftKey = 512
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = HotKeyManager.kVK_ANSI_M // Mキーのキーコード

        var hotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr, hotKeyRef != nil else {
            print("HotKeyManager: Failed to register hotkey (status: \(registerStatus))")
            // イベントハンドラもクリーンアップ
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
            return false
        }

        self.hotKeyRef = hotKeyRef
        print("HotKeyManager: Successfully registered Cmd+Shift+M hotkey")
        return true
    }

    /// グローバルホットキーの登録を解除
    func unregister() {
        // ホットキーの登録解除
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            print("HotKeyManager: Unregistered hotkey")
        }

        // イベントハンドラの削除
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
            print("HotKeyManager: Removed event handler")
        }

        onToggle = nil
    }

    // MARK: - Deinitialization

    deinit {
        unregister()
    }
}

// MARK: - Key Codes

/// よく使用されるキーコードの定義
private extension HotKeyManager {
    static let kVK_ANSI_M: UInt32 = 0x2E
}
