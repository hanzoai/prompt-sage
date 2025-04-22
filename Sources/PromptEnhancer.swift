import Foundation

// Supported LLM providers
enum LLMProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic Claude"
    case googleAI = "Google Gemini"
    case local = "Local (Ollama)"
    
    var id: String { self.rawValue }
}

// Enhancement style options
enum EnhancementStyle: String, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case concise = "Concise"
    case detailed = "Detailed"
    case technical = "Technical"
    case creative = "Creative"
    
    var id: String { self.rawValue }
}

// Error types for prompt enhancement
enum PromptEnhancerError: Error {
    case apiError(String)
    case networkError(String)
    case invalidResponse
    case rateLimited
    case authenticationFailed
    case noConnection
}

class PromptEnhancer {
    // Default configuration
    private var provider: LLMProvider
    private var apiKey: String
    private var style: EnhancementStyle
    private var temperature: Double
    private var maxTokens: Int
    
    // Statistics for UI display
    private(set) var enhancementsToday: Int = 0
    private(set) var lastEnhancementTime: Date?
    
    // Initialize with default settings
    init() {
        // Load settings from UserDefaults
        if let providerString = UserDefaults.standard.string(forKey: "LLMProvider"),
           let provider = LLMProvider(rawValue: providerString) {
            self.provider = provider
        } else {
            self.provider = .openAI
        }
        
        if let styleString = UserDefaults.standard.string(forKey: "EnhancementStyle"),
           let style = EnhancementStyle(rawValue: styleString) {
            self.style = style
        } else {
            self.style = .balanced
        }
        
        // Try to get API key from environment variables first, then from UserDefaults
        self.apiKey = self.getAPIKeyForProvider(provider: self.provider)
        self.temperature = UserDefaults.standard.double(forKey: "Temperature")
        self.maxTokens = UserDefaults.standard.integer(forKey: "MaxTokens")
        
        // Set defaults if not found
        if self.temperature == 0 {
            self.temperature = 0.7
        }
        
        if self.maxTokens == 0 {
            self.maxTokens = 1000
        }
        
        // Save the API key to UserDefaults if it was found in environment variables
        if !self.apiKey.isEmpty && UserDefaults.standard.string(forKey: "APIKey") == nil {
            UserDefaults.standard.set(self.apiKey, forKey: "APIKey")
        }
        
        // Load enhancement statistics
        self.enhancementsToday = UserDefaults.standard.integer(forKey: "EnhancementsToday")
        if let lastTime = UserDefaults.standard.object(forKey: "LastEnhancementTime") as? Date {
            self.lastEnhancementTime = lastTime
        }
        
        // Reset daily count if needed
        checkAndResetDailyCount()
    }
    
    // Helper method to get API key from environment variables or UserDefaults
    private func getAPIKeyForProvider(provider: LLMProvider) -> String {
        // Check for environment variables first based on provider
        let envVariable: String?
        switch provider {
        case .openAI:
            envVariable = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        case .anthropic:
            envVariable = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        case .googleAI:
            envVariable = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"]
        case .local:
            // Local Ollama doesn't typically need an API key
            envVariable = nil
        }
        
        // Return environment variable if available, otherwise fall back to UserDefaults
        if let key = envVariable, !key.isEmpty {
            return key
        } else {
            return UserDefaults.standard.string(forKey: "APIKey") ?? ""
        }
    }
    
    // Update configuration
    func updateConfiguration(provider: LLMProvider? = nil, 
                           apiKey: String? = nil,
                           style: EnhancementStyle? = nil,
                           temperature: Double? = nil,
                           maxTokens: Int? = nil) {
        if let provider = provider {
            self.provider = provider
            UserDefaults.standard.set(provider.rawValue, forKey: "LLMProvider")
            
            // When provider changes, check for environment variable for new provider
            if apiKey == nil {
                let newKey = getAPIKeyForProvider(provider: provider)
                if !newKey.isEmpty {
                    self.apiKey = newKey
                    UserDefaults.standard.set(newKey, forKey: "APIKey")
                }
            }
        }
        
        if let apiKey = apiKey {
            self.apiKey = apiKey
            UserDefaults.standard.set(apiKey, forKey: "APIKey")
        }
        
        if let style = style {
            self.style = style
            UserDefaults.standard.set(style.rawValue, forKey: "EnhancementStyle")
        }
        
        if let temperature = temperature {
            self.temperature = temperature
            UserDefaults.standard.set(temperature, forKey: "Temperature")
        }
        
        if let maxTokens = maxTokens {
            self.maxTokens = maxTokens
            UserDefaults.standard.set(maxTokens, forKey: "MaxTokens")
        }
    }
    
    // Enhance a prompt using the configured LLM
    func enhancePrompt(_ prompt: String) async throws -> String {
        // Validate configuration
        guard !apiKey.isEmpty || provider == .local else {
            throw PromptEnhancerError.authenticationFailed
        }
        
        // Check for free tier limits
        if UserDefaults.standard.bool(forKey: "IsFreeTier") {
            let enhancementLimit = 5
            if enhancementsToday >= enhancementLimit {
                throw PromptEnhancerError.rateLimited
            }
        }
        
        // Create the system prompt for enhancement
        let systemPrompt = createSystemPrompt()
        
        // Enhance the prompt based on the provider
        let enhancedPrompt: String
        
        switch provider {
        case .openAI:
            enhancedPrompt = try await enhanceWithOpenAI(prompt, systemPrompt: systemPrompt)
        case .anthropic:
            enhancedPrompt = try await enhanceWithAnthropic(prompt, systemPrompt: systemPrompt)
        case .googleAI:
            enhancedPrompt = try await enhanceWithGoogleAI(prompt, systemPrompt: systemPrompt)
        case .local:
            enhancedPrompt = try await enhanceWithLocal(prompt, systemPrompt: systemPrompt)
        }
        
        // Update statistics
        updateEnhancementStatistics()
        
        return enhancedPrompt
    }
    
    // Create the system prompt based on the enhancement style
    private func createSystemPrompt() -> String {
        var systemPrompt = "You are an expert in prompt engineering, helping to improve a user's prompt for better AI results. "
        
        // Add style-specific instructions
        switch style {
        case .balanced:
            systemPrompt += "Enhance the prompt with a balanced approach that improves clarity, specificity, and structure without changing the core intent."
        case .concise:
            systemPrompt += "Make the prompt more concise while retaining all key information. Remove redundancy and focus on precise language."
        case .detailed:
            systemPrompt += "Expand the prompt with relevant details, context, and structure. Add helpful specifics that would lead to a more comprehensive AI response."
        case .technical:
            systemPrompt += "Optimize the prompt for technical accuracy and precision. Use domain-specific terminology where appropriate and add structure for technical depth."
        case .creative:
            systemPrompt += "Enhance the prompt to encourage more creative, innovative, and imaginative responses from AI. Add elements that inspire unique perspectives."
        }
        
        // Common guidelines
        systemPrompt += "\n\nFollow these guidelines:\n"
        systemPrompt += "1. Maintain the user's original intent and core request\n"
        systemPrompt += "2. Improve clarity, specificity, and organization\n"
        systemPrompt += "3. Add helpful context or constraints as needed\n"
        systemPrompt += "4. Structure longer prompts with numbered points or sections\n"
        systemPrompt += "5. Only return the enhanced prompt, with no explanations or additional text\n"
        
        return systemPrompt
    }
    
    // MARK: - Provider-specific Implementation
    
    // Enhance with OpenAI (GPT-4, GPT-3.5)
    private func enhanceWithOpenAI(_ prompt: String, systemPrompt: String) async throws -> String {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        // Determine model based on user preferences
        let model = UserDefaults.standard.string(forKey: "OpenAIModel") ?? "gpt-4o"
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Original prompt: \(prompt)"]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PromptEnhancerError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 429 {
                    throw PromptEnhancerError.rateLimited
                } else if httpResponse.statusCode == 401 {
                    throw PromptEnhancerError.authenticationFailed
                } else {
                    throw PromptEnhancerError.apiError("HTTP Status: \(httpResponse.statusCode)")
                }
            }
            
            // Parse the response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw PromptEnhancerError.invalidResponse
            }
        } catch let error as PromptEnhancerError {
            throw error
        } catch {
            throw PromptEnhancerError.networkError(error.localizedDescription)
        }
    }
    
    // Enhance with Anthropic Claude
    private func enhanceWithAnthropic(_ prompt: String, systemPrompt: String) async throws -> String {
        let endpoint = "https://api.anthropic.com/v1/messages"
        
        // Determine model based on user preferences
        let model = UserDefaults.standard.string(forKey: "AnthropicModel") ?? "claude-3-haiku-20240307"
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Original prompt: \(prompt)"]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "x-api-key")
        request.addValue("anthropic-version-2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PromptEnhancerError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 429 {
                    throw PromptEnhancerError.rateLimited
                } else if httpResponse.statusCode == 401 {
                    throw PromptEnhancerError.authenticationFailed
                } else {
                    throw PromptEnhancerError.apiError("HTTP Status: \(httpResponse.statusCode)")
                }
            }
            
            // Parse the response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstContent = content.first,
               let text = firstContent["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw PromptEnhancerError.invalidResponse
            }
        } catch let error as PromptEnhancerError {
            throw error
        } catch {
            throw PromptEnhancerError.networkError(error.localizedDescription)
        }
    }
    
    // Enhance with Google Gemini
    private func enhanceWithGoogleAI(_ prompt: String, systemPrompt: String) async throws -> String {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
        
        // Add API key to URL
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw PromptEnhancerError.apiError("Invalid URL")
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "\(systemPrompt)\n\nOriginal prompt: \(prompt)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": maxTokens
            ]
        ]
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PromptEnhancerError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 429 {
                    throw PromptEnhancerError.rateLimited
                } else if httpResponse.statusCode == 401 {
                    throw PromptEnhancerError.authenticationFailed
                } else {
                    throw PromptEnhancerError.apiError("HTTP Status: \(httpResponse.statusCode)")
                }
            }
            
            // Parse the response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw PromptEnhancerError.invalidResponse
            }
        } catch let error as PromptEnhancerError {
            throw error
        } catch {
            throw PromptEnhancerError.networkError(error.localizedDescription)
        }
    }
    
    // Enhance using local Ollama
    private func enhanceWithLocal(_ prompt: String, systemPrompt: String) async throws -> String {
        // Default to localhost:11434 for Ollama
        let baseURL = UserDefaults.standard.string(forKey: "LocalModelURL") ?? "http://localhost:11434"
        let endpoint = "\(baseURL)/api/generate"
        
        // Determine model based on user preferences
        let model = UserDefaults.standard.string(forKey: "LocalModel") ?? "llama3"
        
        // Prepare request body 
        let requestBody: [String: Any] = [
            "model": model,
            "prompt": "\(systemPrompt)\n\nOriginal prompt: \(prompt)",
            "stream": false,
            "options": [
                "temperature": temperature,
                "num_predict": maxTokens
            ]
        ]
        
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PromptEnhancerError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode != 200 {
                throw PromptEnhancerError.apiError("HTTP Status: \(httpResponse.statusCode)")
            }
            
            // Parse the response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let response = json["response"] as? String {
                return response.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw PromptEnhancerError.invalidResponse
            }
        } catch let error as PromptEnhancerError {
            throw error
        } catch {
            throw PromptEnhancerError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Statistics Management
    
    // Update statistics after successful enhancement
    private func updateEnhancementStatistics() {
        // Update the count and time
        enhancementsToday += 1
        lastEnhancementTime = Date()
        
        // Save to UserDefaults
        UserDefaults.standard.set(enhancementsToday, forKey: "EnhancementsToday")
        UserDefaults.standard.set(lastEnhancementTime, forKey: "LastEnhancementTime")
    }
    
    // Check if we need to reset the daily count
    private func checkAndResetDailyCount() {
        guard let lastTime = lastEnhancementTime else {
            // No previous enhancements, nothing to reset
            return
        }
        
        // Get the calendar and extract the day component
        let calendar = Calendar.current
        let lastDay = calendar.component(.day, from: lastTime)
        let currentDay = calendar.component(.day, from: Date())
        
        // Reset if day has changed
        if lastDay != currentDay {
            enhancementsToday = 0
            UserDefaults.standard.set(enhancementsToday, forKey: "EnhancementsToday")
        }
    }
    
    // MARK: - Analytics
    
    // Get analytics for the enhanced prompt
    func getEnhancementAnalytics(original: String, enhanced: String) -> [String: Double] {
        var analytics: [String: Double] = [:]
        
        // Calculate length change
        let originalWords = original.split(separator: " ").count
        let enhancedWords = enhanced.split(separator: " ").count
        let lengthChange = originalWords > 0 ? Double(enhancedWords - originalWords) / Double(originalWords) * 100 : 0
        analytics["lengthChange"] = lengthChange
        
        // Calculate clarity improvement (basic heuristic)
        let clarityScore = calculateClarityScore(original: original, enhanced: enhanced)
        analytics["clarityImprovement"] = clarityScore
        
        // Calculate specificity improvement (basic heuristic)
        let specificityScore = calculateSpecificityScore(original: original, enhanced: enhanced)
        analytics["specificityImprovement"] = specificityScore
        
        return analytics
    }
    
    // Calculate a basic clarity score
    private func calculateClarityScore(original: String, enhanced: String) -> Double {
        // This is a very simplified heuristic
        // In a real implementation, this would use more sophisticated NLP techniques
        
        // Check for structure improvements
        let originalHasNumbering = original.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
        let enhancedHasNumbering = enhanced.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
        
        // Check for paragraph structure
        let originalParagraphs = original.components(separatedBy: "\n\n").count
        let enhancedParagraphs = enhanced.components(separatedBy: "\n\n").count
        
        // Check average sentence length (shorter is generally clearer)
        let originalSentences = original.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let enhancedSentences = enhanced.components(separatedBy: ".").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let avgOriginalSentenceLength = originalSentences.isEmpty ? 0 : original.count / originalSentences.count
        let avgEnhancedSentenceLength = enhancedSentences.isEmpty ? 0 : enhanced.count / enhancedSentences.count
        
        // Calculate a score (this is very simplified)
        var score = 0.0
        
        // Structure improvements
        if !originalHasNumbering && enhancedHasNumbering {
            score += 20.0
        }
        
        // Paragraph improvements
        if enhancedParagraphs > originalParagraphs {
            score += 15.0
        }
        
        // Sentence length improvements (if average sentence is shorter but not too short)
        if avgOriginalSentenceLength > 25 && avgEnhancedSentenceLength < avgOriginalSentenceLength && avgEnhancedSentenceLength > 10 {
            score += 15.0
        }
        
        // Base improvement
        score += 30.0
        
        // Cap at 100
        return min(score, 100.0)
    }
    
    // Calculate a basic specificity score
    private func calculateSpecificityScore(original: String, enhanced: String) -> Double {
        // This is a very simplified heuristic
        // In a real implementation, this would use more sophisticated NLP techniques
        
        // Check for specific words/phrases that indicate specificity
        let specificityIndicators = [
            "specifically", "in particular", "for example", "such as",
            "exactly", "precisely", "namely", "in detail",
            "step 1", "step 2", "first", "second", "third",
            "measure", "quantity", "amount", "number",
            "between", "range", "from", "to"
        ]
        
        var originalCount = 0
        var enhancedCount = 0
        
        for indicator in specificityIndicators {
            let originalMatches = original.lowercased().components(separatedBy: indicator).count - 1
            let enhancedMatches = enhanced.lowercased().components(separatedBy: indicator).count - 1
            
            originalCount += originalMatches
            enhancedCount += enhancedMatches
        }
        
        // Check for numbers, which often indicate specificity
        let originalNumberCount = countNumbers(in: original)
        let enhancedNumberCount = countNumbers(in: enhanced)
        
        // Calculate improvement percentage
        let indicatorImprovement = originalCount > 0 
            ? Double(enhancedCount - originalCount) / Double(originalCount) * 50.0
            : (enhancedCount > 0 ? 50.0 : 0.0)
        
        let numberImprovement = originalNumberCount > 0
            ? Double(enhancedNumberCount - originalNumberCount) / Double(originalNumberCount) * 50.0
            : (enhancedNumberCount > 0 ? 50.0 : 0.0)
        
        // Combine scores
        var totalImprovement = indicatorImprovement + numberImprovement
        
        // Add base improvement
        totalImprovement += 30.0
        
        // Cap at 100
        return min(max(totalImprovement, 0.0), 100.0)
    }
    
    // Count numbers in a string
    private func countNumbers(in text: String) -> Int {
        let pattern = #"\d+"#
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return matches.count
        } catch {
            return 0
        }
    }
}
