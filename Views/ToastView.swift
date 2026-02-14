import SwiftUI

/// トースト通知（1.8秒で自動消去）
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool

    enum ToastType {
        case success
        case info
        case warning
        case error

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return Color(hex: "#7ac88a")
            case .info: return Color(hex: "#c4a7ff")
            case .warning: return Color(hex: "#e8c87a")
            case .error: return Color(hex: "#e06060")
            }
        }
    }

    var body: some View {
        if isShowing {
            HStack(spacing: 10) {
                // アイコン
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(type.color)

                // メッセージ
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#eeeeee"))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#161625"))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                // 1.8秒後に自動消去
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Toast Modifier
extension View {
    func toast(message: String, type: ToastView.ToastType = .info, isShowing: Binding<Bool>) -> some View {
        ZStack(alignment: .bottom) {
            self

            if isShowing.wrappedValue {
                ToastView(message: message, type: type, isShowing: isShowing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing.wrappedValue)
    }
}

#Preview {
    VStack(spacing: 100) {
        ToastView(message: "Copied to clipboard!", type: .success, isShowing: .constant(true))
        ToastView(message: "Scanning...", type: .info, isShowing: .constant(true))
        ToastView(message: "CLAUDE.md not found in this repo", type: .error, isShowing: .constant(true))
    }
    .frame(width: 400)
    .padding()
    .background(Color(hex: "#1c1c20"))
}
