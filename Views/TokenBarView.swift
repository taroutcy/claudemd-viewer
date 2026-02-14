import SwiftUI

/// トークン数表示 + プログレスバー（緑/黄/赤）
struct TokenBarView: View {
    let tokenCount: Int

    // トークン数に応じた色を計算
    private var progressColor: Color {
        if tokenCount <= 1000 {
            return Color(hex: "#7ac88a") // 緑
        } else if tokenCount <= 2000 {
            return Color(hex: "#e8c87a") // 黄
        } else {
            return Color(hex: "#e06060") // 赤
        }
    }

    // プログレスバーの進行度（0.0-1.0）
    private var progress: Double {
        let maxTokens: Double = 2500
        return min(Double(tokenCount) / maxTokens, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // トークン数表示
            HStack(spacing: 4) {
                Image(systemName: "diamond")
                    .font(.system(size: 10))
                    .foregroundColor(progressColor)

                Text("~\(tokenCount) tokens")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#eeeeee"))

                Spacer()

                // トークン数のランク表示
                Text(tokenRank)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#999999"))
            }

            // プログレスバー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景バー
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)

                    // プログレスバー
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#161625"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // トークン数に応じたランク表示
    private var tokenRank: String {
        if tokenCount <= 1000 {
            return "Compact"
        } else if tokenCount <= 2000 {
            return "Moderate"
        } else {
            return "Large"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TokenBarView(tokenCount: 450)
        TokenBarView(tokenCount: 1240)
        TokenBarView(tokenCount: 2850)
    }
    .frame(width: 400)
    .padding()
    .background(Color(hex: "#1c1c20"))
}
