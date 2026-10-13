import SwiftUI

public struct AttachedDocumentBadgeView: View {
    public let document: AttachedDocument
    public var onRemove: (() -> Void)? = nil

    public init(document: AttachedDocument, onRemove: (() -> Void)? = nil) {
        self.document = document
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Document Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: iconSystemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Title & Info
            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 5) {
                    Text(document.fileExtension)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(iconColor.opacity(0.12))
                        .foregroundColor(iconColor)
                        .clipShape(Capsule())

                    if let pages = document.pageCount {
                        Text("• \(pages) \(pages == 1 ? "page" : "pages")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Text("• \(document.fileSizeFormatted)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("• ~\(document.tokenEstimate) tokens")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 4)

            // Remove Button (if editable in input bar)
            if let onRemove = onRemove {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onRemove()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove document")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var iconSystemName: String {
        switch document.fileExtension.lowercased() {
        case "pdf":
            return "doc.richtext.fill"
        case "json", "swift", "py", "js", "ts", "html", "css":
            return "chevron.left.forwardslash.chevron.right"
        case "md", "markdown":
            return "doc.text.fill"
        case "csv":
            return "tablecells.fill"
        default:
            return "doc.plaintext.fill"
        }
    }

    private var iconColor: Color {
        switch document.fileExtension.lowercased() {
        case "pdf":
            return .red
        case "json", "swift", "py", "js", "ts":
            return .green
        case "md", "markdown":
            return .purple
        case "csv":
            return .teal
        default:
            return .blue
        }
    }

    private var iconBackgroundColor: Color {
        iconColor
    }
}
