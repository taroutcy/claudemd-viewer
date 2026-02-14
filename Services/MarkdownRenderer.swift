//
//  MarkdownRenderer.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import Foundation
import SwiftUI
import Markdown

/// Markdownテキストを解析してAttributedStringに変換するサービス
class MarkdownRenderer {

    // MARK: - Cache Structure

    private struct CachedResult {
        let attributedString: AttributedString
        let contentHash: Int
        let timestamp: Date
    }

    // MARK: - Cache Storage

    private static var cache: [String: CachedResult] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.claudemdviewer.markdowncache", attributes: .concurrent)
    private static let cacheTTL: TimeInterval = 300 // 5分
    private static let maxCacheSize = 20 // 最大20ファイル

    // 仕様書のカラーパレット
    private struct ColorPalette {
        static let mainText = Color(hex: "#eeeeee")
        static let secondaryText = Color(hex: "#999999")
        static let accentPurple = Color(hex: "#c4a7ff")      // H2見出し用
        static let codeBlockBackground = Color(hex: "#161625")
        static let inlineCodeText = Color(hex: "#e8c87a")
        static let codeBlockText = Color(hex: "#a8d8a8")
    }

    /// MarkdownテキストをAttributedStringに変換（キャッシング対応）
    /// - Parameters:
    ///   - markdownText: 変換するMarkdownテキスト
    ///   - cacheKey: キャッシュキー（ファイルパスなど）。nilの場合はキャッシュしない
    ///   - fileURL: ファイルURL。指定時はファイル更新日時もキャッシュキーに含める
    /// - Returns: レンダリングされたAttributedString
    func render(_ markdownText: String, cacheKey: String? = nil, fileURL: URL? = nil) async -> AttributedString {
        let contentHash = markdownText.hashValue

        // キャッシュキーの生成（ファイルパス + 更新日時）
        let effectiveCacheKey: String?
        if let fileURL = fileURL {
            // 非同期でファイル属性を取得
            let modificationDate = await Task.detached {
                try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
            }.value

            if let modificationDate = modificationDate {
                effectiveCacheKey = "\(fileURL.path)_\(modificationDate.timeIntervalSince1970)"
            } else {
                effectiveCacheKey = fileURL.path
            }
        } else {
            effectiveCacheKey = cacheKey
        }

        // キャッシュチェック
        if let key = effectiveCacheKey,
           let cached = Self.getCachedResult(for: key),
           cached.contentHash == contentHash,
           Date().timeIntervalSince(cached.timestamp) < Self.cacheTTL {
            return cached.attributedString
        }

        // レンダリング実行（CPU集約的処理なのでTask.detachedで実行）
        let attributedString = await Task.detached(priority: .userInitiated) { [self] in
            let document = Document(parsing: markdownText)
            var result = AttributedString()

            for child in document.children {
                result.append(self.renderNode(child))
            }

            return result
        }.value

        // キャッシュに保存
        if let key = effectiveCacheKey {
            Self.setCachedResult(
                CachedResult(
                    attributedString: attributedString,
                    contentHash: contentHash,
                    timestamp: Date()
                ),
                for: key
            )
        }

        return attributedString
    }

    // MARK: - Cache Management

    private static func getCachedResult(for key: String) -> CachedResult? {
        cacheQueue.sync {
            return cache[key]
        }
    }

    private static func setCachedResult(_ result: CachedResult, for key: String) {
        cacheQueue.async(flags: .barrier) {
            // キャッシュサイズ制限チェック
            if cache.count >= maxCacheSize {
                // 最も古いエントリを削除
                if let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key {
                    cache.removeValue(forKey: oldestKey)
                }
            }
            cache[key] = result
        }
    }

    /// キャッシュをクリア（テスト用）
    static func clearCache() {
        cacheQueue.async(flags: .barrier) {
            cache.removeAll()
        }
    }

    /// Markdownノードを再帰的にレンダリング
    private func renderNode(_ node: Markup) -> AttributedString {
        var result = AttributedString()

        if let heading = node as? Heading {
            result = renderHeading(heading)
        } else if let paragraph = node as? Paragraph {
            result = renderParagraph(paragraph)
        } else if let list = node as? UnorderedList {
            result = renderUnorderedList(list)
        } else if let listItem = node as? ListItem {
            result = renderListItem(listItem)
        } else if let codeBlock = node as? CodeBlock {
            result = renderCodeBlock(codeBlock)
        } else if let text = node as? Markdown.Text {
            result = renderText(text)
        } else if let inlineCode = node as? InlineCode {
            result = renderInlineCode(inlineCode)
        } else if let strong = node as? Strong {
            result = renderStrong(strong)
        } else if let emphasis = node as? Emphasis {
            result = renderEmphasis(emphasis)
        } else {
            // その他の子ノードを処理
            for child in node.children {
                result.append(renderNode(child))
            }
        }

        return result
    }

    // MARK: - 見出しのレンダリング

    private func renderHeading(_ heading: Heading) -> AttributedString {
        var text = AttributedString()

        for child in heading.children {
            text.append(renderNode(child))
        }

        // 見出しレベルに応じたフォントサイズとスタイル
        let fontSize: CGFloat
        let fontWeight: Font.Weight
        let color: Color

        switch heading.level {
        case 1:
            fontSize = 24
            fontWeight = .bold
            color = ColorPalette.mainText
        case 2:
            fontSize = 20
            fontWeight = .semibold
            color = ColorPalette.accentPurple  // H2は仕様書の紫色
        case 3:
            fontSize = 18
            fontWeight = .semibold
            color = ColorPalette.mainText
        default:
            fontSize = 16
            fontWeight = .medium
            color = ColorPalette.mainText
        }

        text.font = .system(size: fontSize, weight: fontWeight)
        text.foregroundColor = color

        // 見出しの後に改行を追加
        text.append(AttributedString("\n\n"))

        return text
    }

    // MARK: - 段落のレンダリング

    private func renderParagraph(_ paragraph: Paragraph) -> AttributedString {
        var text = AttributedString()

        for child in paragraph.children {
            text.append(renderNode(child))
        }

        text.font = .system(size: 14)
        text.foregroundColor = ColorPalette.mainText

        // 段落の後に改行を追加
        text.append(AttributedString("\n\n"))

        return text
    }

    // MARK: - リストのレンダリング

    private func renderUnorderedList(_ list: UnorderedList) -> AttributedString {
        var text = AttributedString()

        for child in list.children {
            text.append(renderNode(child))
        }

        // リストの後に改行を追加
        text.append(AttributedString("\n"))

        return text
    }

    private func renderListItem(_ listItem: ListItem) -> AttributedString {
        var text = AttributedString("• ")  // 箇条書きマーカー
        text.foregroundColor = ColorPalette.secondaryText

        for child in listItem.children {
            if let paragraph = child as? Paragraph {
                // リストアイテム内の段落は改行を追加しない
                for paragraphChild in paragraph.children {
                    var itemText = renderNode(paragraphChild)
                    itemText.font = .system(size: 14)
                    itemText.foregroundColor = ColorPalette.mainText
                    text.append(itemText)
                }
            } else {
                text.append(renderNode(child))
            }
        }

        text.append(AttributedString("\n"))

        return text
    }

    // MARK: - コードブロックのレンダリング

    private func renderCodeBlock(_ codeBlock: CodeBlock) -> AttributedString {
        var text = AttributedString(codeBlock.code)

        // コードブロックのスタイル（仕様書の色を適用）
        text.font = .system(size: 13, weight: .regular, design: .monospaced)
        text.foregroundColor = ColorPalette.codeBlockText
        text.backgroundColor = ColorPalette.codeBlockBackground

        // コードブロックの前後に改行と余白を追加
        var result = AttributedString("\n")
        result.append(text)
        result.append(AttributedString("\n\n"))

        return result
    }

    // MARK: - インラインコードのレンダリング

    private func renderInlineCode(_ inlineCode: InlineCode) -> AttributedString {
        var text = AttributedString(inlineCode.code)

        // インラインコードのスタイル（仕様書の色を適用）
        text.font = .system(size: 13, weight: .medium, design: .monospaced)
        text.foregroundColor = ColorPalette.inlineCodeText
        text.backgroundColor = ColorPalette.codeBlockBackground

        return text
    }

    // MARK: - テキストのレンダリング

    private func renderText(_ text: Markdown.Text) -> AttributedString {
        return AttributedString(text.string)
    }

    // MARK: - 強調のレンダリング

    private func renderStrong(_ strong: Strong) -> AttributedString {
        var text = AttributedString()

        for child in strong.children {
            text.append(renderNode(child))
        }

        text.font = .system(size: 14, weight: .bold)

        return text
    }

    private func renderEmphasis(_ emphasis: Emphasis) -> AttributedString {
        var text = AttributedString()

        for child in emphasis.children {
            text.append(renderNode(child))
        }

        text.font = .system(size: 14).italic()

        return text
    }
}
