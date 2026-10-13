import Foundation
import SwiftUI

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var messages: [Message] = []
    @Published public var inputText: String = ""
    @Published public var isTyping: Bool = false
    @Published public var agentStatusText: String? = nil
    @Published public var pendingAttachment: AttachedDocument? = nil
    @Published public var isParsingDocument: Bool = false
    
    private var currentAgentTask: Task<Void, Never>? = nil
    private var streamingMessageId: UUID? = nil
    
    // Agent Configuration
    @Published public var selectedModel: String {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: "AdvanceChatBot_SelectedModel")
        }
    }
    
    @Published public var systemPrompt: String {
        didSet {
            UserDefaults.standard.set(systemPrompt, forKey: "AdvanceChatBot_SystemPrompt")
        }
    }
    
    @Published public var isToolsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isToolsEnabled, forKey: "AdvanceChatBot_ToolsEnabled")
        }
    }
    
    @Published public var temperature: Double {
        didSet {
            UserDefaults.standard.set(temperature, forKey: "AdvanceChatBot_Temperature")
        }
    }
    
    @Published public var isStreamingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isStreamingEnabled, forKey: "AdvanceChatBot_StreamingEnabled")
        }
    }
    
    public init() {
        let savedModel = UserDefaults.standard.string(forKey: "AdvanceChatBot_SelectedModel")
        if savedModel == nil || savedModel == "llama-3.3-70b-versatile" {
            self.selectedModel = "openai/gpt-oss-120b"
            UserDefaults.standard.set("openai/gpt-oss-120b", forKey: "AdvanceChatBot_SelectedModel")
        } else {
            self.selectedModel = savedModel ?? "openai/gpt-oss-120b"
        }
        self.systemPrompt = ChatViewModel.defaultSystemPrompt
        self.isToolsEnabled = UserDefaults.standard.object(forKey: "AdvanceChatBot_ToolsEnabled") as? Bool ?? true
        self.temperature = UserDefaults.standard.object(forKey: "AdvanceChatBot_Temperature") as? Double ?? 0.7
        self.isStreamingEnabled = UserDefaults.standard.object(forKey: "AdvanceChatBot_StreamingEnabled") as? Bool ?? true
        
        loadWelcomeMessage()
    }
    
    public static var defaultSystemPrompt: String {
        return """
        You are Advance ChatBot, an advanced Agentic AI Assistant powered by Groq and Llama 3.3 70B.
        You possess autonomous reasoning and tool-calling capabilities following the ReAct (Reason + Act) framework.

        MANDATORY INSTRUCTIONS:
        1. ATTACHED DOCUMENTS & FILES (Document RAG):
           Whenever files (PDF, TXT, Markdown, code) are attached or the user asks questions about an attached document (including 'what is in the pdf', summaries, or specific questions):
           - YOU MUST CALL the 'search_attached_documents' tool to inspect and retrieve relevant passages!
           - Ground your answers directly in the retrieved passages and cite page numbers when available.
        2. IMAGES & PHOTOS:
           Whenever the user asks for pictures, photos, or images of people, places, animals, or things:
           CALL the 'search_images' tool with the subject!
        3. REAL-TIME TOOLS:
           - Use 'get_latest_news' whenever the user asks for news, headlines, or current events.
           - Use 'web_search' for real-time web research beyond your cutoff.
           - Use 'get_current_weather' for weather conditions.
           - Use 'calculator' for exact math and calculations.
           - Use 'get_current_time_and_date' for the current time or date.
           - Use 'get_device_status' for device battery or OS inquiries.
        4. Format answers cleanly using GitHub Markdown.
        """
    }
    
    public func loadWelcomeMessage() {
        messages = [
            Message(
                content: "Hello! 👋 I'm **Advance ChatBot**, your Agentic AI Assistant powered by **Llama 3.3 70B** on Groq.\n\nI stream answers in real-time, think through problems, autonomously invoke tools (**Document RAG, Images, Live News, Weather, Calculator, Clock, Device Info**), and analyze attached multi-page PDFs and documents.\n\nWhat would you like to explore or solve?",
                isUser: false,
                reasoning: "Welcome state initialized with Llama 3.3 70B, real-time streaming, Document RAG, and tool capabilities."
            )
        ]
    }
    
    public func clearChat() {
        cancelGeneration()
        messages.removeAll()
        pendingAttachment = nil
        DocumentRAGService.shared.clearActiveDocuments()
        loadWelcomeMessage()
    }
    
    public func attachDocument(from url: URL) {
        isParsingDocument = true
        agentStatusText = "Reading document..."
        Task {
            do {
                let doc = try await DocumentRAGService.shared.parseDocument(from: url)
                await MainActor.run {
                    self.pendingAttachment = doc
                    DocumentRAGService.shared.addActiveDocument(doc)
                    self.isParsingDocument = false
                    self.agentStatusText = nil
                }
            } catch {
                await MainActor.run {
                    self.isParsingDocument = false
                    self.agentStatusText = nil
                    let errorMsg = Message(
                        content: "⚠️ **Failed to parse file**: \(error.localizedDescription)\n\nPlease ensure the document is a readable PDF, text, markdown, or code file.",
                        isUser: false,
                        isError: true
                    )
                    self.messages.append(errorMsg)
                }
            }
        }
    }
    
    public func removePendingAttachment() {
        pendingAttachment = nil
    }
    
    public func sendQuickPrompt(_ prompt: String) {
        inputText = prompt
        sendMessage()
    }
    
    public func cancelGeneration() {
        currentAgentTask?.cancel()
        currentAgentTask = nil
        isTyping = false
        agentStatusText = nil
        if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
            messages[idx].isStreaming = false
            if messages[idx].content.isEmpty {
                messages[idx].content = "(Generation stopped by user)"
            }
        }
        streamingMessageId = nil
    }
    
    public func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!trimmed.isEmpty || pendingAttachment != nil), !isTyping else { return }
        
        var attachedDocs: [AttachedDocument] = []
        if let doc = pendingAttachment {
            attachedDocs.append(doc)
            DocumentRAGService.shared.addActiveDocument(doc)
            pendingAttachment = nil
        }
        
        let messageText = trimmed.isEmpty ? "Please review and summarize the attached document: \(attachedDocs.first?.fileName ?? "file")." : trimmed
        
        let userMessage = Message(
            content: messageText,
            isUser: true,
            attachedDocuments: attachedDocs
        )
        messages.append(userMessage)
        inputText = ""
        
        isTyping = true
        agentStatusText = "Thinking & Planning..."
        
        currentAgentTask = Task {
            await executeAgentLoop(userPrompt: messageText, attachedDocs: attachedDocs)
        }
    }
    
    /// ReAct Agent Loop with Real-Time Token Streaming & Document RAG
    private func executeAgentLoop(userPrompt: String, attachedDocs: [AttachedDocument] = []) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        var accumulatedToolExecutions: [ToolExecutionInfo] = []
        var accumulatedReasoning: String = ""
        streamingMessageId = nil
        
        // 1. Build initial conversation payload
        var apiMessages: [[String: Any]] = []
        
        // System Prompt with Lean Document Context Grounding
        var fullSystemPrompt = systemPrompt
        if !DocumentRAGService.shared.activeDocuments.isEmpty {
            fullSystemPrompt += "\n\nACTIVE ATTACHED DOCUMENTS:"
            for doc in DocumentRAGService.shared.activeDocuments {
                let pageInfo = doc.pageCount != nil ? "\(doc.pageCount!) pages, " : ""
                fullSystemPrompt += "\n- [Document: \(doc.fileName) (\(doc.fileExtension), \(pageInfo)\(doc.chunks.count) passages). To inspect contents or answer questions, CALL the 'search_attached_documents' tool.]"
            }
        }
        
        apiMessages.append([
            "role": "system",
            "content": fullSystemPrompt
        ])
        
        // Sliding history window (last 6 messages for context, excluding errors)
        let validMessages = messages.filter { !$0.isError && !$0.content.isEmpty }
        let historyWindow = validMessages.suffix(6)
        for msg in historyWindow {
            apiMessages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }
        
        let toolsToUse = isToolsEnabled ? AgentTools.toolsDefinitions : nil
        
        // ReAct loop (up to 3 iterations for multi-step tool execution)
        let maxIterations = 3
        var currentIteration = 0
        var loopCompleted = false
        
        while currentIteration < maxIterations && !loopCompleted && !Task.isCancelled {
            currentIteration += 1
            
            do {
                let result: GroqCompletionResult
                if isStreamingEnabled {
                    result = try await GroqService.shared.chatCompletionStream(
                        messages: apiMessages,
                        model: selectedModel,
                        tools: toolsToUse,
                        temperature: temperature,
                        onReasoningChunk: { [weak self] chunk in
                            guard let self = self else { return }
                            accumulatedReasoning += chunk
                            self.updateLiveStreamingReasoning(accumulatedReasoning)
                        },
                        onContentChunk: { [weak self] chunk in
                            guard let self = self else { return }
                            self.updateLiveStreamingContent(chunk, tools: accumulatedToolExecutions)
                        }
                    )
                } else {
                    result = try await GroqService.shared.chatCompletion(
                        messages: apiMessages,
                        model: selectedModel,
                        tools: toolsToUse,
                        temperature: temperature
                    )
                }
                
                if Task.isCancelled { break }
                
                // Case A: Model requested tool calls
                if let toolCalls = result.toolCalls, !toolCalls.isEmpty, isToolsEnabled {
                    // Remove temporary streaming bubble if content was empty during tool decision
                    if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
                        if messages[idx].content.isEmpty {
                            messages.remove(at: idx)
                            streamingMessageId = nil
                        }
                    }
                    
                    var assistantMsgPayload: [String: Any] = [
                        "role": "assistant"
                    ]
                    assistantMsgPayload["content"] = result.content ?? ""
                    
                    let toolCallsPayload = toolCalls.map { call -> [String: Any] in
                        return [
                            "id": call.id,
                            "type": "function",
                            "function": [
                                "name": call.name,
                                "arguments": call.arguments
                            ]
                        ]
                    }
                    assistantMsgPayload["tool_calls"] = toolCallsPayload
                    apiMessages.append(assistantMsgPayload)
                    
                    // Execute each tool call
                    for call in toolCalls {
                        if Task.isCancelled { break }
                        agentStatusText = "Executing tool: \(call.name)..."
                        
                        var execInfo = ToolExecutionInfo(
                            id: call.id,
                            toolName: call.name,
                            arguments: call.arguments,
                            status: .calling
                        )
                        
                        let toolResult = await AgentTools.executeTool(name: call.name, argumentsJSON: call.arguments)
                        
                        execInfo.result = toolResult
                        execInfo.status = toolResult.contains("\"error\"") ? .failure : .success
                        accumulatedToolExecutions.append(execInfo)
                        
                        // Append tool result message back to API
                        apiMessages.append([
                            "role": "tool",
                            "tool_call_id": call.id,
                            "name": call.name,
                            "content": toolResult
                        ])
                    }
                    
                    // Update tool cards on streaming message if one was created
                    if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
                        messages[idx].toolCalls = accumulatedToolExecutions
                    }
                    
                    agentStatusText = "Synthesizing answer..."
                    // Continue to next iteration so the model reads tool results and streams final answer
                    continue
                }
                
                // Case B: Final response completed
                loopCompleted = true
                let totalLatency = CFAbsoluteTimeGetCurrent() - startTime
                let finalContent = result.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Done."
                
                // Extract any images gathered by search_images tool
                var extractedImages: [String] = []
                for exec in accumulatedToolExecutions {
                    if exec.toolName == "search_images", let resultStr = exec.result,
                       let data = resultStr.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let images = json["images"] as? [[String: Any]] {
                        for img in images {
                            if let url = img["image_url"] as? String {
                                extractedImages.append(url)
                            }
                        }
                    }
                }
                
                // Finalize or create the message in the array
                if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
                    messages[idx].content = finalContent
                    messages[idx].reasoning = accumulatedReasoning.isEmpty ? nil : accumulatedReasoning
                    messages[idx].toolCalls = accumulatedToolExecutions
                    messages[idx].imageUrls = extractedImages
                    messages[idx].modelName = selectedModel
                    messages[idx].latencySeconds = totalLatency
                    messages[idx].isStreaming = false
                } else {
                    let botMessage = Message(
                        content: finalContent,
                        isUser: false,
                        reasoning: accumulatedReasoning.isEmpty ? nil : accumulatedReasoning,
                        toolCalls: accumulatedToolExecutions,
                        imageUrls: extractedImages,
                        modelName: selectedModel,
                        latencySeconds: totalLatency,
                        isStreaming: false
                    )
                    messages.append(botMessage)
                }
                
            } catch {
                if !Task.isCancelled {
                    loopCompleted = true
                    let totalLatency = CFAbsoluteTimeGetCurrent() - startTime
                    let errorMessage = Message(
                        content: "⚠️ **Error reaching Groq API**: \(error.localizedDescription)\n\nPlease verify your API key and connection in Settings.",
                        isUser: false,
                        reasoning: "API call failed during streaming execution.",
                        toolCalls: accumulatedToolExecutions,
                        modelName: selectedModel,
                        latencySeconds: totalLatency,
                        isError: true
                    )
                    messages.append(errorMessage)
                }
            }
        }
        
        isTyping = false
        agentStatusText = nil
        streamingMessageId = nil
    }
    
    private func updateLiveStreamingReasoning(_ fullReasoning: String) {
        ensureStreamingMessageExists(tools: [])
        if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
            messages[idx].reasoning = fullReasoning
        }
    }
    
    private func updateLiveStreamingContent(_ chunk: String, tools: [ToolExecutionInfo]) {
        ensureStreamingMessageExists(tools: tools)
        if let streamId = streamingMessageId, let idx = messages.firstIndex(where: { $0.id == streamId }) {
            messages[idx].content += chunk
            messages[idx].toolCalls = tools
        }
    }
    
    private func ensureStreamingMessageExists(tools: [ToolExecutionInfo]) {
        if streamingMessageId == nil {
            let newId = UUID()
            let newMsg = Message(
                id: newId,
                content: "",
                isUser: false,
                reasoning: nil,
                toolCalls: tools,
                modelName: selectedModel,
                isStreaming: true
            )
            messages.append(newMsg)
            streamingMessageId = newId
        }
    }
}
