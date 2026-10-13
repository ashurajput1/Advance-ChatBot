import SwiftUI

public struct ReasoningThoughtView: View {
    let reasoning: String
    @State private var isExpanded: Bool = false

    public init(reasoning: String) {
        self.reasoning = reasoning
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.purple)

                    Text(isExpanded ? "Hide Thought Process" : "Thought Process")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.purple.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reasoning)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                        .textSelection(.enabled)

                    HStack {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = reasoning
                        }) {
                            Label("Copy Reasoning", systemImage: "doc.on.doc")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(10)
                .background(Color.purple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 2)
    }
}

#Preview {
    ReasoningThoughtView(reasoning: "The user asks for the weather in Tokyo. Checking if tool is available. Executing get_current_weather with location 'Tokyo'.")
        .padding()
}
