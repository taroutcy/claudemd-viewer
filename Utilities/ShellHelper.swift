import Foundation
import AppKit

/// シェルコマンド実行やアプリケーション起動をサポートするヘルパークラス
final class ShellHelper {

    // MARK: - Editor Operations

    /// システムデフォルトエディタでファイルを開く
    /// - Parameter fileUrl: 開くファイルのURL
    static func openInEditor(_ fileUrl: URL) {
        NSWorkspace.shared.open(fileUrl)
    }

    // MARK: - Terminal Operations

    /// 指定されたディレクトリでTerminal.appを開く
    /// - Parameter directory: 開くディレクトリのURL
    static func openTerminal(at directory: URL) {
        // パスをシェルエスケープ
        let escapedPath = directory.path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Terminal"
            activate
            do script "cd \"\(escapedPath)\""
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            appleScript.executeAndReturnError(&errorDict)

            if let error = errorDict {
                print("ShellHelper: Failed to open Terminal: \(error)")
            }
        }
    }

    // MARK: - Finder Operations

    /// Finderで指定されたディレクトリを開く
    /// - Parameter url: 開くディレクトリのURL
    static func openInFinder(_ url: URL) {
        // selectFileにnilを渡すとディレクトリ自体を選択して開く
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }

    // MARK: - URL Operations

    /// ブラウザで指定されたURLを開く
    /// - Parameter urlString: 開くURLの文字列
    static func openUrl(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            print("ShellHelper: Invalid URL string: \(urlString)")
        }
    }

    /// ブラウザで指定されたURLを開く
    /// - Parameter url: 開くURL
    static func openUrl(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
