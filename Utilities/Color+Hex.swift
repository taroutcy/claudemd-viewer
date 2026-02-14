//
//  Color+Hex.swift
//  ClaudeMDViewer
//
//  Created by Claude Code on 2026-02-08.
//

import SwiftUI

extension Color {
    /// HEX文字列からColorを生成
    /// - Parameter hex: HEXカラーコード（例: "#c4a7ff", "c4a7ff", "#fff"）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - カラーパレット定義（仕様書 4.2）

extension Color {
    // MARK: - Background Colors

    /// 背景色
    static let appBackground = Color(hex: "#1c1c20")

    /// コードブロック背景
    static let codeBlockBackground = Color(hex: "#161625")

    // MARK: - Text Colors

    /// テキスト（メイン）
    static let textMain = Color(hex: "#eeeeee")

    /// テキスト（セカンダリ）
    static let textSecondary = Color(hex: "#999999")

    /// テキスト（薄い）
    static let textDim = Color(hex: "#4a4a55")

    /// テキスト（薄い）- textDimのエイリアス
    static let textTertiary = Color(hex: "#4a4a55")

    /// インラインコード文字
    static let inlineCodeText = Color(hex: "#e8c87a")

    /// コードブロック文字
    static let codeBlockText = Color(hex: "#a8d8a8")

    /// 見出しH2
    static let headingH2 = Color(hex: "#c4a7ff")

    // MARK: - Accent & Status Colors

    /// アクセントカラー（紫）
    static let accent = Color(hex: "#c4a7ff")

    /// 成功（緑）
    static let success = Color(hex: "#7ac88a")

    /// 警告（黄）
    static let warning = Color(hex: "#e8c87a")

    /// エラー・削除（赤）
    static let error = Color(hex: "#e06060")

    // MARK: - Pin Gradient Colors

    /// ピン留めグラデーション開始色
    static let pinGradientStart = Color(hex: "#7c5cbf")

    /// ピン留めグラデーション終了色
    static let pinGradientEnd = Color(hex: "#5b3e9e")

    /// ピン留めグラデーション
    static var pinGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [pinGradientStart, pinGradientEnd]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Token Bar Colors

    /// トークン数に基づいて適切な色を返す
    /// - Parameter tokenCount: トークン数
    /// - Returns: 対応する色（緑・黄・赤）
    static func tokenColor(for tokenCount: Int) -> Color {
        switch tokenCount {
        case 0...1000:
            return .success
        case 1001...2000:
            return .warning
        default:
            return .error
        }
    }
}
