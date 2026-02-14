import Foundation

/// トークン数を概算するユーティリティ
/// 仕様: 文字数 ÷ 4 で概算
struct TokenEstimator {

    /// テキストからトークン数を推定
    /// - Parameter text: 対象のテキスト
    /// - Returns: 推定トークン数
    static func estimate(from text: String?) -> Int {
        guard let text = text else { return 0 }
        return text.count / 4
    }

    /// トークン数に基づいて色のカテゴリを返す
    /// - Parameter tokens: トークン数
    /// - Returns: 色のカテゴリ（green, yellow, red）
    static func colorCategory(for tokens: Int) -> TokenColorCategory {
        switch tokens {
        case 0...1000:
            return .green
        case 1001...2000:
            return .yellow
        default:
            return .red
        }
    }
}

/// トークン数に基づく色のカテゴリ
enum TokenColorCategory {
    case green  // ~1000以下
    case yellow // ~1000-2000
    case red    // ~2000以上
}
