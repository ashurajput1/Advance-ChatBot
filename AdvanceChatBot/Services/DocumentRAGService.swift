import Foundation
import PDFKit
import UniformTypeIdentifiers

public enum DocumentRAGError: LocalizedError {
    case fileAccessDenied
    case emptyDocument
    case unsupportedFileType(String)
    case parsingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Unable to access the selected file. Security permission was denied."
        case .emptyDocument:
            return "The selected document does not contain any readable text."
        case .unsupportedFileType(let ext):
            return "Unsupported file format (.\(ext)). Please upload a PDF, TXT, Markdown, JSON, or code file."
        case .parsingFailed(let msg):
            return "Failed to parse document: \(msg)"
        }
    }
}

public class DocumentRAGService {
    public static let shared = DocumentRAGService()

    /// Active documents loaded in the current chat session
    public var activeDocuments: [AttachedDocument] = []

    private let stopWords: Set<String> = [
        "a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't",
        "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by",
        "can't", "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't",
        "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have",
        "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers", "herself", "him",
        "himself", "his", "how", "how's", "i", "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't",
        "it", "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor",
        "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out",
        "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some",
        "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there",
        "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to",
        "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were",
        "weren't", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "who's",
        "whom", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're",
        "you've", "your", "yours", "yourself", "yourselves", "tell", "show", "give", "please", "file", "document"
    ]

    private init() {}

    /// Parse a selected file into an AttachedDocument with smart chunking
    public func parseDocument(from url: URL) async throws -> AttachedDocument {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let fileName = url.lastPathComponent
        let ext = url.pathExtension.lowercased()

        // Get file size
        var formattedSize = "Unknown size"
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = fileAttributes[.size] as? Int64 {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            formattedSize = bcf.string(fromByteCount: fileSize)
        }

        var fullText = ""
        var pageCount: Int? = nil
        var chunks: [DocumentChunk] = []

        if ext == "pdf" {
            guard let pdfDocument = PDFDocument(url: url) else {
                throw DocumentRAGError.parsingFailed("Could not open PDF file.")
            }
            let count = pdfDocument.pageCount
            pageCount = count

            var allPagesText = ""
            var chunkIdx = 0

            for pageIdx in 0..<count {
                guard let page = pdfDocument.page(at: pageIdx) else { continue }
                let pageStr = page.string ?? ""
                let pageNumber = pageIdx + 1
                let trimmedPage = pageStr.trimmingCharacters(in: .whitespacesAndNewlines)

                if !trimmedPage.isEmpty {
                    allPagesText += "\n\n[Page \(pageNumber)]\n" + trimmedPage

                    // Chunk large pages or keep individual pages
                    let pageChunks = createChunksFromText(trimmedPage, pageNumber: pageNumber, startIndex: chunkIdx)
                    chunks.append(contentsOf: pageChunks)
                    chunkIdx += pageChunks.count
                }
            }

            fullText = allPagesText.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Text-based file (txt, md, json, csv, swift, py, etc.)
            do {
                let data = try Data(contentsOf: url)
                if let str = String(data: data, encoding: .utf8) {
                    fullText = str
                } else if let str = String(data: data, encoding: .ascii) {
                    fullText = str
                } else if let str = String(data: data, encoding: .isoLatin1) {
                    fullText = str
                } else {
                    throw DocumentRAGError.parsingFailed("Text encoding could not be determined.")
                }
            } catch {
                throw DocumentRAGError.parsingFailed(error.localizedDescription)
            }

            fullText = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            chunks = createChunksFromText(fullText, pageNumber: nil, startIndex: 0)
        }

        guard !fullText.isEmpty else {
            throw DocumentRAGError.emptyDocument
        }

        let doc = AttachedDocument(
            fileName: fileName,
            fileExtension: ext.uppercased(),
            fileSizeFormatted: formattedSize,
            pageCount: pageCount,
            fullText: fullText,
            chunks: chunks
        )

        return doc
    }

    /// Splits text into overlapping semantic passages (~600 characters each)
    private func createChunksFromText(_ text: String, pageNumber: Int?, startIndex: Int) -> [DocumentChunk] {
        var result: [DocumentChunk] = []
        let chunkSize = 650
        let overlap = 100

        let paragraphs = text.components(separatedBy: "\n\n")
        var currentChunk = ""
        var chunkCounter = startIndex

        for para in paragraphs {
            let trimmedPara = para.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPara.isEmpty else { continue }

            if currentChunk.count + trimmedPara.count > chunkSize {
                if !currentChunk.isEmpty {
                    result.append(DocumentChunk(
                        id: UUID().uuidString,
                        pageNumber: pageNumber,
                        text: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                        chunkIndex: chunkCounter
                    ))
                    chunkCounter += 1

                    // Carry over overlap
                    let suffixLength = min(overlap, currentChunk.count)
                    let startIdx = currentChunk.index(currentChunk.endIndex, offsetBy: -suffixLength)
                    currentChunk = String(currentChunk[startIdx...]) + "\n" + trimmedPara
                } else {
                    currentChunk = trimmedPara
                }
            } else {
                if currentChunk.isEmpty {
                    currentChunk = trimmedPara
                } else {
                    currentChunk += "\n" + trimmedPara
                }
            }
        }

        if !currentChunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(DocumentChunk(
                id: UUID().uuidString,
                pageNumber: pageNumber,
                text: currentChunk.trimmingCharacters(in: .whitespacesAndNewlines),
                chunkIndex: chunkCounter
            ))
        }

        // Fallback for long single paragraphs without newlines
        if result.isEmpty && !text.isEmpty {
            result.append(DocumentChunk(
                id: UUID().uuidString,
                pageNumber: pageNumber,
                text: text,
                chunkIndex: startIndex
            ))
        }

        return result
    }

    /// Add an active document to the current session
    public func addActiveDocument(_ doc: AttachedDocument) {
        activeDocuments.removeAll(where: { $0.id == doc.id || $0.fileName == doc.fileName })
        activeDocuments.append(doc)
    }

    /// Clear session documents
    public func clearActiveDocuments() {
        activeDocuments.removeAll()
    }

    /// Vectorless RAG search over all active documents
    public func searchActiveDocuments(query: String, maxResults: Int = 4) -> String {
        guard !activeDocuments.isEmpty else {
            return "{\"status\": \"no_active_documents\", \"message\": \"No documents are currently attached to this chat session.\"}"
        }

        let queryTokens = tokenize(query)
        let meaningfulTokens = queryTokens.filter { !stopWords.contains($0) && $0.count > 1 }
        let effectiveTokens = meaningfulTokens.isEmpty ? queryTokens : meaningfulTokens

        var scoredChunks: [(docName: String, pageNumber: Int?, text: String, score: Double)] = []

        for doc in activeDocuments {
            for chunk in doc.chunks {
                let chunkTokens = tokenize(chunk.text)
                let chunkTokenSet = Set(chunkTokens)
                let lowerChunkText = chunk.text.lowercased()
                let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                var score: Double = 0.0

                // 1. Exact query match
                if lowerChunkText.contains(lowerQuery) {
                    score += 15.0
                }

                // 2. Keyword overlap & frequency
                for qToken in effectiveTokens {
                    if chunkTokenSet.contains(qToken) {
                        let frequency = chunkTokens.filter { $0 == qToken }.count
                        score += 3.0 + Double(frequency) * 0.5
                    } else {
                        // Substring match
                        if lowerChunkText.contains(qToken) {
                            score += 1.5
                        }
                    }
                }

                if score > 0 {
                    scoredChunks.append((
                        docName: doc.fileName,
                        pageNumber: chunk.pageNumber,
                        text: chunk.text,
                        score: score
                    ))
                }
            }
        }

        // Sort by relevance score
        scoredChunks.sort { $0.score > $1.score }
        let topResults = scoredChunks.prefix(maxResults)

        if topResults.isEmpty {
            return "{\"status\": \"not_found\", \"query\": \"\(query)\", \"message\": \"No matching passages found in the attached document(s).\"}"
        }

        var resultsArray: [[String: Any]] = []
        for match in topResults {
            var item: [String: Any] = [
                "document": match.docName,
                "score": String(format: "%.1f", match.score),
                "passage": match.text
            ]
            if let p = match.pageNumber {
                item["page"] = p
            }
            resultsArray.append(item)
        }

        let payload: [String: Any] = [
            "status": "success",
            "query": query,
            "match_count": resultsArray.count,
            "results": resultsArray
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{\"status\": \"error\", \"message\": \"Failed to encode search results.\"}"
    }

    private func tokenize(_ text: String) -> [String] {
        return text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
