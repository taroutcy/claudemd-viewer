import AppKit

/// クリップボード操作を提供するユーティリティ
struct ClipboardHelper {

    /// テキストをクリップボードにコピー
    /// - Parameter text: コピーするテキスト
    /// - Returns: 成功した場合true、失敗した場合false
    @discardableResult
    static func copy(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
