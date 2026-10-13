import Foundation

public class QAKnowledgeStore: ObservableObject {
    public static let shared = QAKnowledgeStore()
    private let userDefaultsKey = "AdvanceChatBot_CustomQA_Items"
    private let localSourcePath = "/Users/ashutoshrajput/Desktop/Advance ChatBot/AdvanceChatBot/custom_qa.json"

    @Published public var items: [QAItem] = []

    public init() {
        loadItems()
    }

    /// Loads items prioritizing custom_qa.json so any manual file edits are immediately live
    public func loadItems() {
        // 1. Try reading directly from custom_qa.json (either local development path or bundle)
        if let jsonItems = loadFromJSONFile() {
            // Load user-added custom items from UserDefaults if any exist
            var merged = jsonItems
            if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
               let savedItems = try? JSONDecoder().decode([QAItem].self, from: savedData) {
                let existingIds = Set(merged.map { $0.id })
                let newUnique = savedItems.filter { !existingIds.contains($0.id) }
                merged.append(contentsOf: newUnique)
            }
            self.items = merged
            saveItems()
            return
        }

        // 2. Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([QAItem].self, from: data) {
            self.items = decoded
            return
        }

        // 3. Ultimate fallback
        self.items = QAKnowledgeStore.defaultKnowledge()
        saveItems()
    }

    /// Read directly from custom_qa.json
    public func loadFromJSONFile() -> [QAItem]? {
        // Try local development file first (ideal when editing directly in IDE)
        if FileManager.default.fileExists(atPath: localSourcePath),
           let localData = try? Data(contentsOf: URL(fileURLWithPath: localSourcePath)),
           let decoded = try? JSONDecoder().decode([QAItem].self, from: localData) {
            return decoded
        }

        // Try App Bundle
        if let bundleUrl = Bundle.main.url(forResource: "custom_qa", withExtension: "json"),
           let bundleData = try? Data(contentsOf: bundleUrl),
           let decoded = try? JSONDecoder().decode([QAItem].self, from: bundleData) {
            return decoded
        }

        return nil
    }

    /// Force reloads directly from custom_qa.json
    @discardableResult
    public func reloadFromJSONFile() -> Int {
        if let fileItems = loadFromJSONFile() {
            self.items = fileItems
            saveItems()
            return fileItems.count
        }
        return 0
    }

    public func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    public func addItem(question: String, answer: String, category: String = "Custom") {
        let trimmedQ = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedA = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQ.isEmpty, !trimmedA.isEmpty else { return }

        let newItem = QAItem(question: trimmedQ, answer: trimmedA, category: category)
        items.insert(newItem, at: 0)
        saveItems()
    }

    public func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    public func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveItems()
    }

    public func resetToDefaults() {
        if let jsonItems = loadFromJSONFile() {
            self.items = jsonItems
        } else {
            self.items = QAKnowledgeStore.defaultKnowledge()
        }
        saveItems()
    }

    /// Vectorless RAG search with intelligent stop-word removal and relevance ranking
    public func search(query: String, maxResults: Int = 3) -> [QAItem] {
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let stopWords: Set<String> = [
            "what", "is", "are", "the", "a", "an", "how", "why", "who", "which",
            "can", "you", "tell", "me", "about", "does", "do", "explain", "in", "and", "or", "of", "to"
        ]

        let rawTokens = cleanQuery.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 }
        var queryTokens = Set(rawTokens.filter { !stopWords.contains($0) })
        if queryTokens.isEmpty {
            queryTokens = Set(rawTokens)
        }

        guard !queryTokens.isEmpty else { return [] }

        var scoredItems: [(item: QAItem, score: Double)] = []

        for item in items {
            let qText = item.question.lowercased()
            let aText = item.answer.lowercased()
            var score = 0.0

            // Direct substring matches receive highest score
            if qText.contains(cleanQuery) {
                score += 20.0
            }

            let qTokens = Set(qText.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 })
            let aTokens = Set(aText.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 })

            // Significant overlap in question
            let qOverlap = queryTokens.intersection(qTokens).count
            score += Double(qOverlap) * 8.0

            // Overlap in answer body
            let aOverlap = queryTokens.intersection(aTokens).count
            score += Double(aOverlap) * 2.0

            if score > 0 {
                scoredItems.append((item, score))
            }
        }

        scoredItems.sort { $0.score > $1.score }
        return scoredItems.prefix(maxResults).map { $0.item }
    }

    public static func defaultKnowledge() -> [QAItem] {
        return [
        ]
    }
}
