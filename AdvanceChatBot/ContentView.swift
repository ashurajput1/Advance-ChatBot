import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showingSettings: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages Scroll View
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isTyping {
                                TypingIndicatorView(statusText: viewModel.agentStatusText)
                                    .id("typingIndicator")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: viewModel.messages) { newMessages in
                        if let lastMessage = newMessages.last {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { isTyping in
                        if isTyping {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo("typingIndicator", anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick suggestions chips
                QuickSuggestionsView { suggestion in
                    viewModel.sendQuickPrompt(suggestion)
                }

                Divider()

                // Bottom Input Bar
                ChatInputBarView(
                    text: $viewModel.inputText,
                    isTyping: viewModel.isTyping,
                    pendingAttachment: viewModel.pendingAttachment,
                    onSend: {
                        viewModel.sendMessage()
                    },
                    onStop: {
                        viewModel.cancelGeneration()
                    },
                    onRemoveAttachment: {
                        viewModel.removePendingAttachment()
                    },
                    onAttachFile: { url in
                        viewModel.attachDocument(from: url)
                    }
                )
                .focused($isInputFocused)
            }
            .navigationTitle("Advance ChatBot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Advance ChatBot")
                            .font(.headline)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(viewModel.isTyping ? Color.orange : Color.green)
                                .frame(width: 7, height: 7)
                            Text(shortModelDisplayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Agent Settings", systemImage: "gearshape")
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Clear Conversation", systemImage: "trash")
                        }

                        Button {
                            viewModel.loadWelcomeMessage()
                        } label: {
                            Label("Reset to Welcome", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AgentSettingsView(viewModel: viewModel)
            }
        }
    }

    private var shortModelDisplayName: String {
        if viewModel.isTyping {
            return viewModel.agentStatusText ?? "Agent Working..."
        }
        let full = viewModel.selectedModel
        if full.contains("/") {
            return full.components(separatedBy: "/").last ?? full
        }
        return full
    }
}

#Preview {
    ContentView()
}
