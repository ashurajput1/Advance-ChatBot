import SwiftUI

public struct ToolActivityCardView: View {
    let toolCalls: [ToolExecutionInfo]
    @State private var isExpanded: Bool = false

    public init(toolCalls: [ToolExecutionInfo]) {
        self.toolCalls = toolCalls
    }

    public var body: some View {
        if !toolCalls.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)

                        Text(toolHeaderTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    VStack(spacing: 8) {
                        ForEach(toolCalls) { call in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    toolIcon(for: call.toolName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.blue)

                                    Text(call.toolName)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    statusBadge(call.status)
                                }

                                if !call.arguments.isEmpty {
                                    Text("Input: \(call.arguments)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }

                                if let result = call.result, !result.isEmpty {
                                    Text("Result: \(result)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.primary.opacity(0.85))
                                        .lineLimit(4)
                                        .padding(6)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, 2)
        }
    }

    private var toolHeaderTitle: String {
        if toolCalls.count == 1 {
            return "Used Tool: \(toolCalls[0].toolName)"
        } else {
            return "Used \(toolCalls.count) Tools (\(toolCalls.map { $0.toolName }.joined(separator: ", ")))"
        }
    }

    private func toolIcon(for name: String) -> Image {
        switch name {
        case "search_images": return Image(systemName: "photo.fill")
        case "web_search": return Image(systemName: "globe")
        case "get_latest_news": return Image(systemName: "newspaper.fill")
        case "get_current_weather": return Image(systemName: "cloud.sun.fill")
        case "calculator": return Image(systemName: "plus.forwardslash.minus")
        case "get_current_time_and_date": return Image(systemName: "clock.fill")
        case "get_device_status": return Image(systemName: "battery.100.bolt")
        case "lookup_custom_qa": return Image(systemName: "books.vertical.fill")
        default: return Image(systemName: "gearshape.fill")
        }
    }

    private func statusBadge(_ status: ToolExecutionStatus) -> some View {
        HStack(spacing: 3) {
            switch status {
            case .calling:
                ProgressView()
                    .scaleEffect(0.6)
                Text("Running")
                    .font(.caption2)
                    .foregroundColor(.orange)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 11))
                Text("Success")
                    .font(.caption2)
                    .foregroundColor(.green)
            case .failure:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 11))
                Text("Failed")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}
