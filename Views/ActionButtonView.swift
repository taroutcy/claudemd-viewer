import SwiftUI

/// アクションボタンコンポーネント（アイコン + ラベル）
struct ActionButtonView: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            VStack(spacing: 6) {
                // アイコン
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#c4a7ff"))
                    .frame(height: 20)

                // ラベル
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#eeeeee"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isPressed
                            ? Color(hex: "#c4a7ff").opacity(0.15)
                            : (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isPressed
                            ? Color(hex: "#c4a7ff").opacity(0.4)
                            : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.08)),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ActionButtonView(icon: "doc.on.doc", label: "Copy") {}
        ActionButtonView(icon: "pencil", label: "Edit") {}
        ActionButtonView(icon: "terminal", label: "Terminal") {}
        ActionButtonView(icon: "folder", label: "Finder") {}
    }
    .frame(width: 400)
    .padding()
    .background(Color(hex: "#1c1c20"))
}
