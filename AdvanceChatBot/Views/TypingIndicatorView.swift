import SwiftUI

public struct TypingIndicatorView: View {
    public var statusText: String?
    @State private var dotScales: [CGFloat] = [0.4, 0.4, 0.4]

    public init(statusText: String? = nil) {
        self.statusText = statusText
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.purple.opacity(0.8))
                            .frame(width: 7, height: 7)
                            .scaleEffect(dotScales[index])
                    }
                }

                if let text = statusText, !text.isEmpty {
                    Text(text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .padding(.horizontal, 12)
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
            ) {
                dotScales[index] = 1.2
            }
        }
    }
}

#Preview {
    TypingIndicatorView(statusText: "Executing tool: get_current_weather...")
}
