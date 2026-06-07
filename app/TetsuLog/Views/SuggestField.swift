import SwiftUI

/// 過去入力からサジェストを出すテキストフィールド。
/// 駅名・路線名の表記ゆれ（「新宿」「JR新宿」「新宿駅」）を抑え、集計を壊さないための要。
struct SuggestField: View {
    let title: String
    @Binding var text: String
    let suggestions: [String]

    private var matches: [String] {
        guard !text.isEmpty else { return [] }
        let lower = text.lowercased()
        return suggestions
            .filter { $0.lowercased().contains(lower) && $0 != text }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(title, text: $text)
            if !matches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(matches, id: \.self) { s in
                            Button {
                                text = s
                                Haptics.tick()
                            } label: {
                                Text(s)
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(.orange.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
