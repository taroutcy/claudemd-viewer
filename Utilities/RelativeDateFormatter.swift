import Foundation

/// 相対的な日付を "2h ago", "3d ago" 形式でフォーマットするユーティリティ
struct RelativeDateFormatter {

    /// 日付を相対的な形式でフォーマット
    /// - Parameter date: フォーマットする日付
    /// - Returns: "2h ago", "3d ago" 等の相対的な日付文字列
    static func string(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        // 秒単位
        if interval < 60 {
            return "just now"
        }

        // 分単位 (1分 ~ 59分)
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        // 時間単位 (1時間 ~ 23時間)
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)h ago"
        }

        // 日単位 (1日 ~ 29日)
        let days = Int(interval / 86400)
        if days < 30 {
            return "\(days)d ago"
        }

        // 月単位 (1ヶ月 ~ 11ヶ月)
        let months = Int(interval / 2592000) // 30日を1ヶ月として概算
        if months < 12 {
            return "\(months)mo ago"
        }

        // 年単位
        let years = Int(interval / 31536000) // 365日を1年として概算
        return "\(years)y ago"
    }
}
