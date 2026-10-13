import SwiftUI

public struct MessageBubbleView: View {
    public let message: Message

    public init(message: Message) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
            } else {
                botAvatar
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Attached Documents (if any)
                if !message.attachedDocuments.isEmpty {
                    VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                        ForEach(message.attachedDocuments) { doc in
                            AttachedDocumentBadgeView(document: doc)
                        }
                    }
                }

                // Agent Reasoning Drawer (if present)
                if !message.isUser, let reasoning = message.reasoning, !reasoning.isEmpty {
                    ReasoningThoughtView(reasoning: reasoning)
                }

                // Agent Tool Activity (if tools were executed)
                if !message.isUser, !message.toolCalls.isEmpty {
                    ToolActivityCardView(toolCalls: message.toolCalls)
                }

                // Attached Images (AsyncImage Gallery)
                if !allImageUrls.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(allImageUrls, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .padding()
                                            Spacer()
                                        }
                                        .frame(height: 180)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))

                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxWidth: 320, maxHeight: 260)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)

                                    case .failure:
                                        HStack {
                                            Image(systemName: "photo.badge.exclamationmark")
                                                .foregroundColor(.secondary)
                                            Text("Unable to load picture")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 80)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))

                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Message Text (if non-empty)
                if !cleanContent.isEmpty {
                    Text(LocalizedStringKey(cleanContent))
                        .font(.body)
                        .foregroundColor(message.isUser ? .white : .primary)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if message.isUser {
                                    LinearGradient(
                                        colors: [Color.blue, Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else if message.isError {
                                    Color.red.opacity(0.12)
                                } else {
                                    Color(.secondarySystemBackground)
                                }
                            }
                        )
                        .overlay(
                            Group {
                                if message.isError {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                }
                            }
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = message.content
                            } label: {
                                Label("Copy Text", systemImage: "doc.on.doc")
                            }
                        }
                }

                // Footer: Model info + Latency + Timestamp
                HStack(spacing: 6) {
                    if !message.isUser {
                        if message.isStreaming {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                Text("Streaming live...")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else if let model = message.modelName {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                                Text(shortModelName(model))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }

                            if let latency = message.latencySeconds {
                                Text("• \(String(format: "%.2fs", latency))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }

            if message.isUser {
                userAvatar
            } else {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 12)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)),
            removal: .opacity
        ))
    }

    private var allImageUrls: [String] {
        if !message.imageUrls.isEmpty {
            return message.imageUrls
        }
        // Extract markdown images: ![...](https://...)
        let pattern = #"!\[.*?\]\((https?://[^\s\)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = message.content as NSString
            let matches = regex.matches(in: message.content, range: NSRange(location: 0, length: nsString.length))
            let urls = matches.map { nsString.substring(with: $0.range(at: 1)) }
            if !urls.isEmpty {
                return urls
            }
        }
        return []
    }

    private var cleanContent: String {
        let pattern = #"!\[.*?\]\((https?://[^\s\)]+)\)"#
        let stripped = message.content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func shortModelName(_ full: String) -> String {
        if full.contains("/") {
            return full.components(separatedBy: "/").last ?? full
        }
        return full
    }

    private var botAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 34, height: 34)
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 34, height: 34)
            Image(systemName: "person.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
