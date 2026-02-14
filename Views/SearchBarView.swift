import SwiftUI

/// 検索バー + クリアボタン
struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            // 検索アイコン
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#999999"))

            // 検索テキストフィールド
            TextField("Search projects...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#eeeeee"))

            // クリアボタン（テキストがある場合のみ表示）
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#4a4a55"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#161625"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    SearchBarView(searchText: .constant("test"))
        .frame(width: 400)
        .padding()
        .background(Color(hex: "#1c1c20"))
}
