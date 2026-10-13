import SwiftUI
import UniformTypeIdentifiers

struct ChatInputBarView: View {
    @Binding var text: String
    var isTyping: Bool
    var pendingAttachment: AttachedDocument? = nil
    var onSend: () -> Void
    var onStop: (() -> Void)? = nil
    var onRemoveAttachment: (() -> Void)? = nil
    var onAttachFile: ((URL) -> Void)? = nil

    @State private var showingFileImporter: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            // Attached Document Preview Chip (if any)
            if let doc = pendingAttachment {
                AttachedDocumentBadgeView(document: doc, onRemove: onRemoveAttachment)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Paperclip Attachment Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingFileImporter = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 40, height: 40)

                        Image(systemName: "paperclip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(pendingAttachment != nil ? Color.blue : Color.primary)
                    }
                }
                .disabled(isTyping)
                .accessibilityLabel("Attach PDF or Document")

                // Text Field
                TextField("Message Advance ChatBot...", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )

                // Send or Stop Button
                if isTyping {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onStop?()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.red.opacity(0.35), radius: 5, x: 0, y: 2)

                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Stop generating")
                } else {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSend()
                    }) {
                        ZStack {
                            Circle()
                                .fill(canSend ? LinearGradient(
                                    colors: [Color.blue, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!canSend)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: canSend)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isTyping)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: pendingAttachment != nil)
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [
                .pdf,
                .plainText,
                .text,
                .json,
                .commaSeparatedText,
                .sourceCode
            ],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    onAttachFile?(url)
                }
            case .failure(let error):
                print("Error picking document: \(error.localizedDescription)")
            }
        }
    }

    private var canSend: Bool {
        (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingAttachment != nil) && !isTyping
    }
}

#Preview {
    ChatInputBarView(text: .constant("Hello world"), isTyping: false) {}
}
