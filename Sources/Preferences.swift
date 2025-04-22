import SwiftUI

struct Preferences: View {
    // App state
    @State private var isActive: Bool = true
    @State private var showNotifications: Bool = true
    @State private var automaticEnhancement: Bool = false
    
    // LLM configuration
    @State private var selectedProvider: LLMProvider = .openAI
    @State private var apiKey: String = ""
    @State private var enhancementStyle: EnhancementStyle = .balanced
    @State private var temperature: Double = 0.7
    
    // OpenAI specific
    @State private var openAIModel: String = "gpt-4o"
    @State private var openAIModels = ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
    
    // Anthropic specific
    @State private var anthropicModel: String = "claude-3-haiku-20240307"
    @State private var anthropicModels = ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
    
    // Google specific
    @State private var googleModel: String = "gemini-pro"
    @State private var googleModels = ["gemini-pro", "gemini-ultra"]
    
    // Local model specific
    @State private var localModel: String = "llama3"
    @State private var localModels = ["llama3", "mistral", "mixtral", "phi3"]
    @State private var localModelURL: String = "http://localhost:11434"
    
    // Custom settings
    @State private var customAITools: String = ""
    @State private var customPromptPatterns: String = ""
    
    // UI state
    @State private var selectedTab = 0
    
    // Accent color
    let accentColor = Color(red: 108/255, green: 92/255, blue: 231/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("General", index: 0)
                tabButton("LLM Settings", index: 1)
                tabButton("Detection", index: 2)
                tabButton("Advanced", index: 3)
            }
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // Content area
            TabView(selection: $selectedTab) {
                generalTab
                    .tag(0)
                
                llmSettingsTab
                    .tag(1)
                
                detectionTab
                    .tag(2)
                
                advancedTab
                    .tag(3)
            }
            .tabViewStyle(DefaultTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
            .padding(20)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadPreferences()
        }
    }
    
    // MARK: - Tabs
    
    // General settings tab
    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Toggle("Active", isOn: $isActive)
                .onChange(of: isActive) { _ in savePreferences() }
            
            Toggle("Show Notifications", isOn: $showNotifications)
                .onChange(of: showNotifications) { _ in savePreferences() }
            
            Toggle("Automatic Enhancement", isOn: $automaticEnhancement)
                .onChange(of: automaticEnhancement) { _ in savePreferences() }
            
            Text("Enhancement Style")
                .font(.system(size: 14, weight: .medium))
            
            Picker("Style", selection: $enhancementStyle) {
                ForEach(EnhancementStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: enhancementStyle) { _ in savePreferences() }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // LLM Settings tab
    private var llmSettingsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LLM Provider Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Picker("Provider", selection: $selectedProvider) {
                ForEach(LLMProvider.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedProvider) { _ in savePreferences() }
            
            // API Key (except for local provider)
            if selectedProvider != .local {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.system(size: 14, weight: .medium))
                    
                    SecureField("Enter API key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: apiKey) { _ in savePreferences() }
                }
            }
            
            // Provider-specific settings
            switch selectedProvider {
            case .openAI:
                providerModelPicker(title: "OpenAI Model", selection: $openAIModel, options: openAIModels)
            case .anthropic:
                providerModelPicker(title: "Claude Model", selection: $anthropicModel, options: anthropicModels)
            case .googleAI:
                providerModelPicker(title: "Gemini Model", selection: $googleModel, options: googleModels)
            case .local:
                VStack(alignment: .leading, spacing: 16) {
                    providerModelPicker(title: "Local Model", selection: $localModel, options: localModels)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ollama URL")
                            .font(.system(size: 14, weight: .medium))
                        
                        TextField("http://localhost:11434", text: $localModelURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: localModelURL) { _ in savePreferences() }
                    }
                }
            }
            
            // Temperature slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Temperature")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f", temperature))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Slider(value: $temperature, in: 0...1, step: 0.1)
                    .accentColor(accentColor)
                    .onChange(of: temperature) { _ in savePreferences() }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // Detection settings tab
    private var detectionTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detection Settings")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom AI Tools (One per line)")
                    .font(.system(size: 14, weight: .medium))
                
                TextEditor(text: $customAITools)
                    .font(.system(size: 12))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: customAITools) { _ in savePreferences() }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Prompt Patterns (One per line)")
                    .font(.system(size: 14, weight: .medium))
                
                TextEditor(text: $customPromptPatterns)
                    .font(.system(size: 12))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: customPromptPatterns) { _ in savePreferences() }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // Advanced settings tab
    private var advancedTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Settings")
                .font(.system(size: 18, weight: .semibold))
            
            Button(action: {
                // Reset all preferences to defaults
                resetPreferences()
            }) {
                Text("Reset All Preferences")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            Text("About PromptSage")
                .font(.system(size: 14, weight: .medium))
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            HStack {
                Text("© 2025 PromptSage")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    // Open website
                    NSWorkspace.shared.open(URL(string: "https://promptsage.com")!)
                }) {
                    Text("Visit Website")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - Components
    
    // Tab button
    private func tabButton(_ title: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 14, weight: selectedTab == index ? .semibold : .regular))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(selectedTab == index ? accentColor : Color.gray)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(selectedTab == index ? accentColor : Color.clear),
                    alignment: .bottom
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Provider model picker
    private func providerModelPicker(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(PopUpButtonStyle())
            .onChange(of: selection.wrappedValue) { _ in savePreferences() }
        }
    }
    
    // MARK: - Preferences Management
    
    // Load preferences from UserDefaults
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        // General settings
        isActive = defaults.bool(forKey: "IsActive")
        showNotifications = defaults.bool(forKey: "ShowNotifications")
        automaticEnhancement = defaults.bool(forKey: "AutomaticEnhancement")
        
        // Get enhancement style
        if let styleString = defaults.string(forKey: "EnhancementStyle"),
           let style = EnhancementStyle(rawValue: styleString) {
            enhancementStyle = style
        }
        
        // LLM settings
        if let providerString = defaults.string(forKey: "LLMProvider"),
           let provider = LLMProvider(rawValue: providerString) {
            selectedProvider = provider
        }
        
        apiKey = defaults.string(forKey: "APIKey") ?? ""
        temperature = defaults.double(forKey: "Temperature")
        
        // Set default temperature if not found
        if temperature == 0 {
            temperature = 0.7
        }
        
        // Provider-specific models
        openAIModel = defaults.string(forKey: "OpenAIModel") ?? "gpt-4o"
        anthropicModel = defaults.string(forKey: "AnthropicModel") ?? "claude-3-haiku-20240307"
        googleModel = defaults.string(forKey: "GoogleModel") ?? "gemini-pro"
        localModel = defaults.string(forKey: "LocalModel") ?? "llama3"
        localModelURL = defaults.string(forKey: "LocalModelURL") ?? "http://localhost:11434"
        
        // Custom detection settings
        if let customTools = defaults.stringArray(forKey: "CustomAITools") {
            customAITools = customTools.joined(separator: "\n")
        }
        
        if let customPatterns = defaults.stringArray(forKey: "CustomPromptPatterns") {
            customPromptPatterns = customPatterns.joined(separator: "\n")
        }
    }
    
    // Save preferences to UserDefaults
    private func savePreferences() {
        let defaults = UserDefaults.standard
        
        // General settings
        defaults.set(isActive, forKey: "IsActive")
        defaults.set(showNotifications, forKey: "ShowNotifications")
        defaults.set(automaticEnhancement, forKey: "AutomaticEnhancement")
        defaults.set(enhancementStyle.rawValue, forKey: "EnhancementStyle")
        
        // LLM settings
        defaults.set(selectedProvider.rawValue, forKey: "LLMProvider")
        defaults.set(apiKey, forKey: "APIKey")
        defaults.set(temperature, forKey: "Temperature")
        
        // Provider-specific models
        defaults.set(openAIModel, forKey: "OpenAIModel")
        defaults.set(anthropicModel, forKey: "AnthropicModel")
        defaults.set(googleModel, forKey: "GoogleModel")
        defaults.set(localModel, forKey: "LocalModel")
        defaults.set(localModelURL, forKey: "LocalModelURL")
        
        // Custom detection settings
        let customToolsArray = customAITools.split(separator: "\n").map { String($0) }
        defaults.set(customToolsArray, forKey: "CustomAITools")
        
        let customPatternsArray = customPromptPatterns.split(separator: "\n").map { String($0) }
        defaults.set(customPatternsArray, forKey: "CustomPromptPatterns")
    }
    
    // Reset preferences to defaults
    private func resetPreferences() {
        // General settings
        isActive = true
        showNotifications = true
        automaticEnhancement = false
        enhancementStyle = .balanced
        
        // LLM settings
        selectedProvider = .openAI
        apiKey = ""
        temperature = 0.7
        
        // Provider-specific models
        openAIModel = "gpt-4o"
        anthropicModel = "claude-3-haiku-20240307"
        googleModel = "gemini-pro"
        localModel = "llama3"
        localModelURL = "http://localhost:11434"
        
        // Custom detection settings
        customAITools = ""
        customPromptPatterns = ""
        
        // Save the defaults
        savePreferences()
    }
}

// Preview provider
struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}
