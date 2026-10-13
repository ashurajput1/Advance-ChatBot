import SwiftUI

public struct QuickSuggestionsView: View {
    public let onSelect: (String) -> Void

    public let suggestions = [
        "🌤️ What's the weather in Tokyo?",
        "🧮 What is 185 * 45 - 230?",
        "📚 What is Vectorless RAG?",
        "⏰ What is the current date and time?",
        "📱 What is my device battery status?",
        "🌐 What are the latest developments in AI agents?"
    ]

    public init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSelect(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    QuickSuggestionsView { _ in }
}
