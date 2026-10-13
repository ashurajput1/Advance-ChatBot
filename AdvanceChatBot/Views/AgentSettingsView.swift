import SwiftUI

public struct AgentSettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput: String = ""
    @State private var showApiKey: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var showingKnowledgeManager: Bool = false

    let availableModels = [
        ("openai/gpt-oss-120b", "GPT OSS 120B (High Reasoning)"),
        ("openai/gpt-oss-20b", "GPT OSS 20B (Ultra Fast)"),
        ("qwen/qwen3.8-27b", "Qwen 3.8 27B")
    ]

    let personaPresets = [
        ("Agentic Assistant", ChatViewModel.defaultSystemPrompt),
        ("Senior iOS Engineer", "You are an expert Principal Apple Platform & SwiftUI Engineer. Provide clean, modern Swift code using Swift Concurrency, MVVM, and Apple Human Interface Guidelines."),
        ("Research Analyst", "You are an analytical research agent. When answering, formulate clear hypotheses, use tools to gather external facts, cite sources, and provide structured conclusions."),
        ("Concise Mode", "You are a concise, direct AI assistant. Provide minimal, highly direct, actionable answers with no fluff.")
    ]

    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Groq API Key
                Section(header: Label("Groq API Key", systemImage: "key.fill")) {
                    HStack {
                        if showApiKey {
                            TextField("Groq API Key (gsk_...)", text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Groq API Key (gsk_...)", text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                        }

                        Button(action: {
                            showApiKey.toggle()
                        }) {
                            Image(systemName: showApiKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Save API Key") {
                        GroqService.shared.apiKey = apiKeyInput
                        showSavedAlert = true
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Default key active & verified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Section 2: Model Selection
                Section(header: Label("LLM Model", systemImage: "cpu")) {
                    Picker("Active Model", selection: $viewModel.selectedModel) {
                        ForEach(availableModels, id: \.0) { modelId, displayName in
                            Text(displayName).tag(modelId)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Selected: \(viewModel.selectedModel)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Section 3: Agent Capabilities & Tools
                Section(header: Label("Agent Capabilities", systemImage: "wrench.and.screwdriver")) {
                    Toggle("Real-Time Streaming", isOn: $viewModel.isStreamingEnabled)
                    Text("Stream tokens in real-time as they generate with live ReAct reasoning and stop generation support.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Toggle("Enable Tool Calling (ReAct)", isOn: $viewModel.isToolsEnabled)

                    if viewModel.isToolsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Tools:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text("• 📄 Document RAG (PDF, TXT, Code Semantic Search)\n• 📸 Image Search (High-Res Photos & Celebrities)\n• 📰 Breaking News (Live Global News)\n• 🌐 Web Search (DuckDuckGo)\n• ⛅ Weather (Open-Meteo)\n• 🧮 Calculator (Deterministic Math)\n• ⏰ Real-time Clock & Date\n• 📱 Device Battery & OS Info\n• 📚 Custom Q&A Store (Vectorless RAG)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", viewModel.temperature))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $viewModel.temperature, in: 0.0...1.0, step: 0.05)
                    }
                }

                // Section 4: Custom Q&A Knowledge Base
                Section(header: Label("Knowledge Base (RAG)", systemImage: "books.vertical.fill")) {
                    NavigationLink(destination: QAKnowledgeManagerView()) {
                        HStack {
                            Text("Manage Custom Q&A Items")
                            Spacer()
                            Text("\(QAKnowledgeStore.shared.items.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Add your own question & answer pairs. The agent will autonomously search and cite them.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Section 5: System Prompt & Personas
                Section(header: Label("System Persona", systemImage: "person.crop.circle")) {
                    Menu("Apply Preset Persona...") {
                        ForEach(personaPresets, id: \.0) { name, prompt in
                            Button(name) {
                                viewModel.systemPrompt = prompt
                            }
                        }
                    }

                    TextEditor(text: $viewModel.systemPrompt)
                        .frame(minHeight: 120)
                        .font(.caption)

                    Button("Reset to Default Persona") {
                        viewModel.systemPrompt = ChatViewModel.defaultSystemPrompt
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Agent Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKeyInput = GroqService.shared.apiKey
            }
            .alert("API Key Saved", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your Groq API key has been stored successfully.")
            }
        }
    }
}

// MARK: - Q&A Knowledge Base Manager View

public struct QAKnowledgeManagerView: View {
    @ObservedObject private var store = QAKnowledgeStore.shared
    @State private var showingAddSheet: Bool = false
    @State private var newQuestion: String = ""
    @State private var newAnswer: String = ""
    @State private var newCategory: String = "Custom"
    @State private var searchQuery: String = ""
    @State private var showingReloadAlert: Bool = false
    @State private var reloadedCount: Int = 0

    public init() {}

    var filteredItems: [QAItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return store.items
        }
        return store.search(query: searchQuery, maxResults: 20)
    }

    public var body: some View {
        List {
            Section {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Label("Add New Q&A Pair", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)
                }

                Button(action: {
                    let count = store.reloadFromJSONFile()
                    reloadedCount = count
                    showingReloadAlert = true
                }) {
                    Label("Reload from custom_qa.json", systemImage: "arrow.clockwise.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }

            Section(header: Text("Stored Knowledge (\(filteredItems.count))")) {
                if filteredItems.isEmpty {
                    Text("No Q&A items found.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.category.uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())

                                Spacer()

                                Text(item.dateAdded, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Text("Q: \(item.question)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("A: \(item.answer)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        store.deleteItem(at: indexSet)
                    }
                }
            }

            Section {
                Button(role: .destructive, action: {
                    store.resetToDefaults()
                }) {
                    Label("Reset to Default Knowledge Base", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .searchable(text: $searchQuery, prompt: "Search Q&A store...")
        .navigationTitle("Knowledge Base")
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    Section("Question") {
                        TextField("Enter question or prompt...", text: $newQuestion, axis: .vertical)
                            .lineLimit(2...4)
                    }

                    Section("Answer") {
                        TextField("Enter accurate answer...", text: $newAnswer, axis: .vertical)
                            .lineLimit(4...8)
                    }

                    Section("Category") {
                        TextField("e.g. Products, Rules, SwiftUI", text: $newCategory)
                    }
                }
                .navigationTitle("New Q&A Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            store.addItem(question: newQuestion, answer: newAnswer, category: newCategory)
                            newQuestion = ""
                            newAnswer = ""
                            newCategory = "Custom"
                            showingAddSheet = false
                        }
                        .disabled(newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert("Knowledge Base Reloaded", isPresented: $showingReloadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Successfully loaded \(reloadedCount) items from custom_qa.json.")
        }
    }
}
