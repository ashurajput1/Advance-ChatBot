import Foundation

public enum ToolExecutionStatus: String, Codable {
    case calling
    case success
    case failure
}

public struct ToolExecutionInfo: Identifiable, Codable, Equatable {
    public let id: String
    public let toolName: String
    public let arguments: String
    public var result: String?
    public var status: ToolExecutionStatus

    public init(id: String = UUID().uuidString, toolName: String, arguments: String, result: String? = nil, status: ToolExecutionStatus = .calling) {
        self.id = id
        self.toolName = toolName
        self.arguments = arguments
        self.result = result
        self.status = status
    }
}

public struct DocumentChunk: Identifiable, Codable, Equatable {
    public let id: String
    public let pageNumber: Int?
    public let text: String
    public let chunkIndex: Int

    public init(id: String = UUID().uuidString, pageNumber: Int? = nil, text: String, chunkIndex: Int) {
        self.id = id
        self.pageNumber = pageNumber
        self.text = text
        self.chunkIndex = chunkIndex
    }
}

public struct AttachedDocument: Identifiable, Codable, Equatable {
    public let id: UUID
    public let fileName: String
    public let fileExtension: String
    public let fileSizeFormatted: String
    public let pageCount: Int?
    public let fullText: String
    public let chunks: [DocumentChunk]
    public let tokenEstimate: Int

    public init(
        id: UUID = UUID(),
        fileName: String,
        fileExtension: String,
        fileSizeFormatted: String,
        pageCount: Int? = nil,
        fullText: String,
        chunks: [DocumentChunk] = []
    ) {
        self.id = id
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.fileSizeFormatted = fileSizeFormatted
        self.pageCount = pageCount
        self.fullText = fullText
        self.chunks = chunks
        self.tokenEstimate = max(1, fullText.count / 4)
    }
}

public struct Message: Identifiable, Equatable {
    public let id: UUID
    public var content: String
    public let isUser: Bool
    public let timestamp: Date
    public var reasoning: String?
    public var toolCalls: [ToolExecutionInfo]
    public var imageUrls: [String]
    public var modelName: String?
    public var latencySeconds: Double?
    public var isError: Bool
    public var isStreaming: Bool
    public var attachedDocuments: [AttachedDocument]

    public init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        reasoning: String? = nil,
        toolCalls: [ToolExecutionInfo] = [],
        imageUrls: [String] = [],
        modelName: String? = nil,
        latencySeconds: Double? = nil,
        isError: Bool = false,
        isStreaming: Bool = false,
        attachedDocuments: [AttachedDocument] = []
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.reasoning = reasoning
        self.toolCalls = toolCalls
        self.imageUrls = imageUrls
        self.modelName = modelName
        self.latencySeconds = latencySeconds
        self.isError = isError
        self.isStreaming = isStreaming
        self.attachedDocuments = attachedDocuments
    }
}

public struct QAItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var question: String
    public var answer: String
    public var category: String
    public var dateAdded: Date

    public init(id: UUID = UUID(), question: String, answer: String, category: String = "General", dateAdded: Date = Date()) {
        self.id = id
        self.question = question
        self.answer = answer
        self.category = category
        self.dateAdded = dateAdded
    }

    enum CodingKeys: String, CodingKey {
        case id, question, answer, category, dateAdded
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idString = try? container.decode(String.self, forKey: .id), let parsedUUID = UUID(uuidString: idString) {
            self.id = parsedUUID
        } else if let parsedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = parsedId
        } else {
            self.id = UUID()
        }
        self.question = try container.decode(String.self, forKey: .question)
        self.answer = try container.decode(String.self, forKey: .answer)
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "General"
        self.dateAdded = (try? container.decode(Date.self, forKey: .dateAdded)) ?? Date()
    }
}
