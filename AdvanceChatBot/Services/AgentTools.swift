import Foundation
import UIKit

public struct AgentTools {
    
    /// JSON Schemas describing tools to Groq LLM
    public static var toolsDefinitions: [[String: Any]] {
        return [
            [
                "type": "function",
                "function": [
                    "name": "lookup_custom_qa",
                    "description": "MANDATORY: Call this tool FIRST whenever the user asks ANY question, definition, concept, or FAQ. Searches the user's custom Questions & Answers database (Vectorless RAG) to find their exact curated answers.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "query": [
                                "type": "string",
                                "description": "Search query terms or question keywords to find matching Q&A entries"
                            ]
                        ],
                        "required": ["query"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "web_search",
                    "description": "Search the live web for fresh facts, news, definitions, recent events, or information beyond your training cutoff.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "query": [
                                "type": "string",
                                "description": "The search query string"
                            ]
                        ],
                        "required": ["query"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "get_current_weather",
                    "description": "Get real-time weather and temperature for any city in the world.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "city": [
                                "type": "string",
                                "description": "City name, e.g., Tokyo, London, New York, New Delhi"
                            ]
                        ],
                        "required": ["city"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "calculator",
                    "description": "Accurately evaluate mathematical expressions and arithmetic. Use this whenever calculations are needed to avoid hallucination.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "expression": [
                                "type": "string",
                                "description": "Math expression to evaluate, e.g. '125 * 34 + 92', 'sqrt(144)', '2500 * 0.18'"
                            ]
                        ],
                        "required": ["expression"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "get_current_time_and_date",
                    "description": "Get current real-time clock, date, day of week, and timezone grounding.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "timezone": [
                                "type": "string",
                                "description": "Optional timezone identifier like 'America/New_York', or leave empty for device local time"
                            ]
                        ]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "get_device_status",
                    "description": "Retrieve current iOS device status including battery level, state, iOS version, and model.",
                    "parameters": [
                        "type": "object",
                        "properties": [:]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "get_latest_news",
                    "description": "Fetch real-time breaking news headlines, articles, and top stories on any topic, world news, technology, business, or sports. Always use this whenever the user asks about current events, today's news, or general news.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "topic": [
                                "type": "string",
                                "description": "The news subject, topic, or search term (e.g., 'technology', 'world', 'business', 'artificial intelligence', 'sports')"
                            ]
                        ],
                        "required": ["topic"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "search_images",
                    "description": "Searches and retrieves real high-resolution photos, pictures, and images of people, celebrities, places, animals, movies, or things. ALWAYS call this tool whenever the user asks for a picture, photo, or image (e.g. 'pic of Katrina Kaif', 'show photo of Eiffel Tower').",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "query": [
                                "type": "string",
                                "description": "The person, place, or thing to find pictures of (e.g., 'Katrina Kaif', 'Eiffel Tower', 'Golden Retriever')"
                            ]
                        ],
                        "required": ["query"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "search_attached_documents",
                    "description": "Searches the contents of user-attached files, PDFs, text files, and documents for relevant passages, facts, or answers. Call this tool whenever the user asks questions about their uploaded document, report, resume, or file.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "query": [
                                "type": "string",
                                "description": "Keywords, questions, or topics to search for within the attached document"
                            ]
                        ],
                        "required": ["query"]
                    ]
                ]
            ]
        ]
    }
    
    /// Dispatch tool calls by name
    public static func executeTool(name: String, argumentsJSON: String) async -> String {
        let args = parseArguments(argumentsJSON)
        
        switch name {
        case "lookup_custom_qa":
            let query = args["query"] as? String ?? ""
            return executeLookupQA(query: query)
            
        case "search_attached_documents":
            let query = args["query"] as? String ?? ""
            return executeSearchAttachedDocuments(query: query)
            
        case "search_images":
            let query = args["query"] as? String ?? ""
            return await executeSearchImages(query: query)
            
        case "web_search":
            let query = args["query"] as? String ?? ""
            return await executeWebSearch(query: query)
            
        case "get_latest_news":
            let topic = args["topic"] as? String ?? "top news"
            return await executeLatestNews(topic: topic)
            
        case "get_current_weather":
            let city = args["city"] as? String ?? ""
            return await executeWeather(city: city)
            
        case "calculator":
            let expression = args["expression"] as? String ?? ""
            return executeCalculator(expression: expression)
            
        case "get_current_time_and_date":
            let timezone = args["timezone"] as? String
            return executeTimeAndDate(timezoneIdentifier: timezone)
            
        case "get_device_status":
            return await executeDeviceStatus()
            
        default:
            return "{\"error\": \"Tool '\(name)' is not recognized.\"}"
        }
    }
    
    // MARK: - Tool Implementations
    
    private static func executeSearchAttachedDocuments(query: String) -> String {
        return DocumentRAGService.shared.searchActiveDocuments(query: query, maxResults: 4)
    }
    
    private static func executeLookupQA(query: String) -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "{\"results\": [], \"message\": \"No search query provided.\"}"
        }
        
        let matches = QAKnowledgeStore.shared.search(query: query, maxResults: 3)
        if matches.isEmpty {
            return "{\"results\": [], \"message\": \"No matching entries found in the custom Q&A knowledge base for query: '\(query)'\"}"
        }
        
        let formatted = matches.map { item -> [String: String] in
            return [
                "question": item.question,
                "answer": item.answer,
                "category": item.category
            ]
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: ["results": formatted], options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{\"results\": \"Found \(matches.count) items.\"}"
    }
    
    private static func executeSearchImages(query: String) async -> String {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty,
              let encoded = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=\(encoded)&gsrlimit=3&prop=pageimages&pithumbsize=800&format=json") else {
            return "{\"error\": \"Invalid image search query.\"}"
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("AdvanceChatBot/1.0 (iOS; Contact: support@example.com)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryDict = json["query"] as? [String: Any],
                  let pages = queryDict["pages"] as? [String: [String: Any]] else {
                return "{\"query\": \"\(cleanQuery)\", \"message\": \"No images found for this subject.\"}"
            }
            
            var images: [[String: Any]] = []
            for (_, page) in pages {
                if let thumb = page["thumbnail"] as? [String: Any],
                   let sourceUrl = thumb["source"] as? String {
                    let title = page["title"] as? String ?? cleanQuery
                    images.append([
                        "title": title,
                        "image_url": sourceUrl,
                        "width": thumb["width"] as? Int ?? 600,
                        "height": thumb["height"] as? Int ?? 800
                    ])
                }
            }
            
            // If generator search had no thumbnails, try direct titles query fallback
            if images.isEmpty,
               let directUrl = URL(string: "https://en.wikipedia.org/w/api.php?action=query&titles=\(encoded)&prop=pageimages&pithumbsize=800&format=json") {
                var directReq = URLRequest(url: directUrl)
                directReq.timeoutInterval = 6.0
                directReq.setValue("AdvanceChatBot/1.0 (iOS; Contact: support@example.com)", forHTTPHeaderField: "User-Agent")
                if let (dData, _) = try? await URLSession.shared.data(for: directReq),
                   let dJson = try? JSONSerialization.jsonObject(with: dData) as? [String: Any],
                   let dQuery = dJson["query"] as? [String: Any],
                   let dPages = dQuery["pages"] as? [String: [String: Any]] {
                    for (_, page) in dPages {
                        if let thumb = page["thumbnail"] as? [String: Any],
                           let sourceUrl = thumb["source"] as? String {
                            images.append([
                                "title": page["title"] as? String ?? cleanQuery,
                                "image_url": sourceUrl
                            ])
                        }
                    }
                }
            }
            
            if !images.isEmpty,
               let outData = try? JSONSerialization.data(withJSONObject: ["query": cleanQuery, "images": images], options: .prettyPrinted),
               let outStr = String(data: outData, encoding: .utf8) {
                return outStr
            }
            
            return "{\"query\": \"\(cleanQuery)\", \"message\": \"No direct image preview available for this query.\"}"
        } catch {
            return "{\"error\": \"Image search failed: \(error.localizedDescription)\"}"
        }
    }
    
    private static func executeWebSearch(query: String) async -> String {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1&skip_disambig=1") else {
            return "{\"error\": \"Invalid web search query.\"}"
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let abstractText = json["AbstractText"] as? String ?? ""
                let heading = json["Heading"] as? String ?? ""
                let abstractSource = json["AbstractSource"] as? String ?? ""
                
                var results: [String: Any] = [:]
                if !abstractText.isEmpty {
                    results["heading"] = heading
                    results["summary"] = abstractText
                    results["source"] = abstractSource
                }
                
                if let related = json["RelatedTopics"] as? [[String: Any]] {
                    let textList = related.compactMap { $0["Text"] as? String }.prefix(3)
                    if !textList.isEmpty {
                        results["related_snippets"] = Array(textList)
                    }
                }
                
                if !results.isEmpty,
                   let outData = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted),
                   let outStr = String(data: outData, encoding: .utf8) {
                    return outStr
                }
            }
            
            // Fallback lightweight query response if DuckDuckGo Instant Answer was sparse
            return "{\"query\": \"\(query)\", \"message\": \"Web search query executed. No instant snippet available, answer based on foundational facts.\"}"
        } catch {
            return "{\"error\": \"Web search failed: \(error.localizedDescription)\"}"
        }
    }
    
    private static func executeWeather(city: String) async -> String {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encodedCity = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let geocodingUrl = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedCity)&count=1&language=en&format=json") else {
            return "{\"error\": \"Invalid city name.\"}"
        }
        
        do {
            var geoReq = URLRequest(url: geocodingUrl)
            geoReq.timeoutInterval = 6.0
            let (geoData, _) = try await URLSession.shared.data(for: geoReq)
            guard let geoJson = try? JSONSerialization.jsonObject(with: geoData) as? [String: Any],
                  let results = geoJson["results"] as? [[String: Any]],
                  let first = results.first,
                  let lat = first["latitude"] as? Double,
                  let lon = first["longitude"] as? Double,
                  let resolvedName = first["name"] as? String else {
                return "{\"error\": \"Could not locate coordinates for city: '\(city)'\"}"
            }
            
            let country = first["country"] as? String ?? ""
            let forecastUrlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m"
            guard let forecastUrl = URL(string: forecastUrlStr) else {
                return "{\"error\": \"Could not build forecast URL.\"}"
            }
            
            var forecastReq = URLRequest(url: forecastUrl)
            forecastReq.timeoutInterval = 6.0
            let (forecastData, _) = try await URLSession.shared.data(for: forecastReq)
            
            guard let forecastJson = try? JSONSerialization.jsonObject(with: forecastData) as? [String: Any],
                  let current = forecastJson["current"] as? [String: Any] else {
                return "{\"error\": \"Failed to read current weather data.\"}"
            }
            
            let temp = current["temperature_2m"] as? Double ?? 0.0
            let feelsLike = current["apparent_temperature"] as? Double ?? temp
            let humidity = current["relative_humidity_2m"] as? Int ?? 0
            let windSpeed = current["wind_speed_10m"] as? Double ?? 0.0
            let weatherCode = current["weather_code"] as? Int ?? 0
            let condition = weatherCodeDescription(weatherCode)
            
            let weatherSummary: [String: Any] = [
                "location": "\(resolvedName), \(country)",
                "temperature_celsius": temp,
                "feels_like_celsius": feelsLike,
                "condition": condition,
                "humidity_percent": humidity,
                "wind_speed_kmh": windSpeed
            ]
            
            if let outData = try? JSONSerialization.data(withJSONObject: weatherSummary, options: .prettyPrinted),
               let outStr = String(data: outData, encoding: .utf8) {
                return outStr
            }
            return "{\"temperature\": \(temp), \"condition\": \"\(condition)\"}"
        } catch {
            return "{\"error\": \"Weather lookup failed: \(error.localizedDescription)\"}"
        }
    }
    
    private static func weatherCodeDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Mainly clear, partly cloudy"
        case 45, 48: return "Fog and depositing rime fog"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain (slight to heavy)"
        case 71, 73, 75: return "Snow fall"
        case 80, 81, 82: return "Rain showers"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Partly cloudy"
        }
    }
    
    private static func executeCalculator(expression: String) -> String {
        let cleaned = expression
            .replacingOccurrences(of: "x", with: "*")
            .replacingOccurrences(of: "X", with: "*")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        // Security check: Only permit mathematical characters
        let allowed = CharacterSet(charactersIn: "0123456789+-*/()., ")
        if cleaned.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "{\"error\": \"Expression contains unsupported characters.\"}"
        }
        
        do {
            let expr = NSExpression(format: cleaned)
            if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 6
                formatter.minimumFractionDigits = 0
                formatter.numberStyle = .decimal
                let formattedResult = formatter.string(from: result) ?? "\(result)"
                return "{\"expression\": \"\(cleaned)\", \"result\": \(result), \"formatted\": \"\(formattedResult)\"}"
            }
            return "{\"error\": \"Could not evaluate expression.\"}"
        } catch {
            return "{\"error\": \"Calculation error: \(error.localizedDescription)\"}"
        }
    }
    
    private static func executeTimeAndDate(timezoneIdentifier: String?) -> String {
        let now = Date()
        let formatter = DateFormatter()
        
        if let tzId = timezoneIdentifier, !tzId.isEmpty, let tz = TimeZone(identifier: tzId) {
            formatter.timeZone = tz
        } else {
            formatter.timeZone = TimeZone.current
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        let fullDate = formatter.string(from: now)
        
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        let readableDate = formatter.string(from: now)
        
        formatter.dateFormat = "h:mm:ss a"
        let readableTime = formatter.string(from: now)
        
        let tzName = formatter.timeZone.identifier
        
        let payload: [String: String] = [
            "iso_formatted": fullDate,
            "readable_date": readableDate,
            "readable_time": readableTime,
            "timezone": tzName
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{\"date\": \"\(readableDate)\", \"time\": \"\(readableTime)\"}"
    }
    
    @MainActor
    private static func executeDeviceStatus() -> String {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        let batteryLevel = device.batteryLevel >= 0 ? "\(Int(device.batteryLevel * 100))%" : "Unknown"
        var batteryStateStr = "Unknown"
        switch device.batteryState {
        case .charging: batteryStateStr = "Charging ⚡"
        case .full: batteryStateStr = "Full 🔋"
        case .unplugged: batteryStateStr = "Unplugged (On Battery)"
        default: batteryStateStr = "Unknown"
        }
        
        let payload: [String: String] = [
            "device_model": device.model,
            "system_name": device.systemName,
            "system_version": device.systemVersion,
            "battery_level": batteryLevel,
            "battery_status": batteryStateStr
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{\"battery\": \"\(batteryLevel)\", \"state\": \"\(batteryStateStr)\"}"
    }
    
    private static func executeLatestNews(topic: String) async -> String {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let url = URL(string: "https://ok.surf/api/v1/cors/news-feed") else {
            return "{\"error\": \"Invalid news API endpoint URL.\"}"
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else {
                return "{\"error\": \"Unable to retrieve JSON news payload from server.\"}"
            }
            
            // Category mapping
            let categoryMapping: [String: String] = [
                "tech": "Technology", "technology": "Technology", "ai": "Technology", "software": "Technology", "apple": "Technology", "google": "Technology",
                "business": "Business", "finance": "Business", "economy": "Business", "stocks": "Business", "market": "Business",
                "world": "World", "global": "World", "international": "World", "war": "World",
                "sports": "Sports", "football": "Sports", "basketball": "Sports", "cricket": "Sports",
                "science": "Science", "space": "Science", "nasa": "Science", "climate": "Science",
                "health": "Health", "medical": "Health", "medicine": "Health", "virus": "Health",
                "entertainment": "Entertainment", "movies": "Entertainment", "hollywood": "Entertainment", "music": "Entertainment",
                "us": "US", "usa": "US", "america": "US"
            ]
            
            var matchedArticles: [[String: String]] = []
            
            // Check direct category match
            if let matchedCat = categoryMapping[cleanTopic], let articles = jsonDict[matchedCat] {
                for item in articles.prefix(5) {
                    matchedArticles.append([
                        "title": item["title"] as? String ?? "",
                        "source": item["source"] as? String ?? "News",
                        "url": item["link"] as? String ?? "",
                        "category": matchedCat
                    ])
                }
            } else {
                // Keyword search across all categories
                let queryTokens = cleanTopic.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 }
                
                for (category, articles) in jsonDict {
                    for item in articles {
                        let title = (item["title"] as? String ?? "").lowercased()
                        if queryTokens.contains(where: { title.contains($0) }) {
                            matchedArticles.append([
                                "title": item["title"] as? String ?? "",
                                "source": item["source"] as? String ?? "News",
                                "url": item["link"] as? String ?? "",
                                "category": category
                            ])
                            if matchedArticles.count >= 5 { break }
                        }
                    }
                    if matchedArticles.count >= 5 { break }
                }
                
                // Fallback to top world and tech headlines if query didn't match specific filter
                if matchedArticles.isEmpty {
                    let topWorld = jsonDict["World"]?.prefix(3) ?? []
                    let topTech = jsonDict["Technology"]?.prefix(2) ?? []
                    for item in (topWorld + topTech) {
                        matchedArticles.append([
                            "title": item["title"] as? String ?? "",
                            "source": item["source"] as? String ?? "News",
                            "url": item["link"] as? String ?? "",
                            "category": "Top News"
                        ])
                    }
                }
            }
            
            let outputPayload: [String: Any] = [
                "api_type": "JSON REST API",
                "query": topic,
                "articles_count": matchedArticles.count,
                "articles": matchedArticles
            ]
            
            if let outputData = try? JSONSerialization.data(withJSONObject: outputPayload, options: .prettyPrinted),
               let outputString = String(data: outputData, encoding: .utf8) {
                return outputString
            }
            
            return "{\"articles_count\": \(matchedArticles.count)}"
        } catch {
            return "{\"error\": \"News REST API request failed: \(error.localizedDescription)\"}"
        }
    }
    
    private static func parseArguments(_ jsonString: String) -> [String: Any] {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
