# Advance ChatBot — Agentic AI (SwiftUI + Groq)

A native iOS Agentic AI ChatBot application built with **SwiftUI**, powered by **Groq Cloud LLMs**, implementing autonomous **ReAct (Reason + Act)** workflows, modular tool calling, reasoning transparency, and in-memory **Vectorless RAG**.

---

## 🚀 Key Agentic AI Features

- **Groq Ultra-Fast LPU Inference**:
  - Connects to Groq's high-speed API (`openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `qwen/qwen3.8-27b`).
  - Pre-configured with your active Groq API key, editable directly in the in-app settings sheet.
- **Autonomous ReAct Agent Loop**:
  - Executes the **Thought $\rightarrow$ Action $\rightarrow$ Observation $\rightarrow$ Response** cycle taught in the Agentic AI course.
  - The model inspects user intent, calls appropriate tools, observes results, and synthesizes answers.
- **Modular Tool Calling Suite**:
  - 🌐 `web_search`: Live DuckDuckGo search integration for up-to-date facts.
  - ⛅ `get_current_weather`: Real-time Open-Meteo weather and forecast for any city.
  - 🧮 `calculator`: Deterministic `NSExpression` math computation to eliminate hallucinations.
  - ⏰ `get_current_time_and_date`: Real-time clock, timezone, and calendar grounding.
  - 📱 `get_device_status`: iOS battery level, charging state, and device version.
  - 📚 `lookup_custom_qa`: In-app Vectorless RAG store search.
- **Custom Question & Answer Knowledge Base (Vectorless RAG)**:
  - Add, edit, or delete custom Q&A pairs directly in the **Knowledge Base Manager**.
  - The agent autonomously searches and cites your custom Q&A entries when answering domain questions.
- **Reasoning Process Visibility ("Thinking Box")**:
  - Expandable **"Thought Process"** card displaying the model's inner reasoning chain before answering.
- **Tool Invocations Card**:
  - Expandable badge displaying which tools were called, their input arguments, execution status, and observations.
- **Agent Settings Sheet**:
  - Switch models (`gpt-oss-120b`, `gpt-oss-20b`, `qwen3.8-27b`).
  - Toggle tool-calling on or off.
  - Adjust temperature and system prompt presets (Senior iOS Engineer, Research Analyst, Concise Mode).
  - Open the Q&A Knowledge Base Manager.

---

## 🏗️ Architecture

```
AdvanceChatBot/
├── AdvanceChatBot.xcodeproj/           # Xcode project file
├── AdvanceChatBot/
│   ├── AdvanceChatBotApp.swift         # Main App entry point (@main)
│   ├── ContentView.swift               # Root view with navigation & chat stream
│   ├── Models/
│   │   └── Message.swift               # Message, ToolExecutionInfo, and QAItem models
│   ├── Services/
│   │   ├── GroqService.swift           # Asynchronous Groq API client with reasoning & tools
│   │   ├── AgentTools.swift            # Tool definitions (JSON Schema) & execution dispatcher
│   │   └── QAKnowledgeStore.swift      # Vectorless RAG store with persistence & search
│   ├── ViewModels/
│   │   └── ChatViewModel.swift         # ReAct agent loop, memory buffer, & published state
│   ├── Views/
│   │   ├── MessageBubbleView.swift     # Message bubble with markdown, thoughts & tool cards
│   │   ├── ReasoningThoughtView.swift  # Collapsible reasoning thought process card
│   │   ├── ToolActivityCardView.swift  # Collapsible tool execution & observation card
│   │   ├── AgentSettingsView.swift     # Model switcher, tool toggles, & Q&A manager
│   │   ├── TypingIndicatorView.swift   # Live agent status ("Thinking...", "Running tool...")
│   │   ├── QuickSuggestionsView.swift  # Quick prompt chips for tools & RAG
│   │   └── ChatInputBarView.swift      # Expanding input bar & send button
│   └── Assets.xcassets/                # Colors & App Icon asset catalog
```

---

## 📱 How to Open and Run

### Option 1: Open in Xcode
```bash
open AdvanceChatBot.xcodeproj
```
1. Select an iOS Simulator (e.g., **iPhone 15 Pro** or **iPhone 16**).
2. Press **Cmd + R** to run.

### Option 2: Build from Terminal
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project AdvanceChatBot.xcodeproj -scheme AdvanceChatBot -destination "generic/platform=iOS Simulator" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```
