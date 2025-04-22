import SwiftUI

struct PromptView: View {
    // Input prompt and result
    let originalPrompt: String
    @State var enhancedPrompt: String = ""
    
    // Callbacks
    let onEnhance: (String) -> Void
    
    // UI state
    @State var isLoading: Bool = true
    @State var error: String? = nil
    @State var analytics: [String: Double] = [:]
    @State private var selectedTab: Int = 1
    
    // Custom accent color
    let accentColor = Color(red: 108/255, green: 92/255, blue: 231/255)
    let backgroundColor = Color(red: 248/255, green: 248/255, blue: 255/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tab switcher
            tabSwitcher
            
            // Content area
            ZStack {
                // Original prompt (tab 0)
                if selectedTab == 0 {
                    promptEditorView(text: originalPrompt, isEditable: false)
                        .transition(.opacity)
                }
                
                // Enhanced prompt (tab 1)
                if selectedTab == 1 {
                    if isLoading {
                        loadingView
                            .transition(.opacity)
                    } else if let errorMessage = error {
                        errorView(message: errorMessage)
                            .transition(.opacity)
                    } else {
                        promptEditorView(text: enhancedPrompt, isEditable: true)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .animation(.easeInOut(duration: 0.2), value: error)
            
            // Analytics and action area
            VStack(spacing: 16) {
                if !isLoading && error == nil && selectedTab == 1 {
                    analyticsView
                }
                
                actionButtonsView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .frame(width: 600, height: 500)
        .background(backgroundColor)
    }
    
    // MARK: - Component Views
    
    // Header view
    private var headerView: some View {
        HStack {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            Text("PromptSage")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(accentColor)
    }
    
    // Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: "Original", isSelected: selectedTab == 0, index: 0)
            tabButton(title: "Enhanced", isSelected: selectedTab == 1, index: 1)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // Tab button
    private func tabButton(title: String, isSelected: Bool, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? accentColor : Color.gray)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? accentColor : Color.clear),
                    alignment: .bottom
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Prompt editor
    private func promptEditorView(text: String, isEditable: Bool) -> some View {
        let binding = Binding<String>(
            get: { text },
            set: { newValue in
                if isEditable {
                    self.enhancedPrompt = newValue
                }
            }
        )
        
        return TextEditor(text: binding)
            .font(.system(size: 14))
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(20)
            .disabled(!isEditable)
    }
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            
            Text("Enhancing your prompt...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
    
    // Error view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Enhancement Error")
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Reset and try again
                isLoading = true
                error = nil
                
                // Re-attempt the enhancement (not implemented in this sample)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    enhancedPrompt = "Enhanced version of the prompt would appear here after retry."
                    isLoading = false
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
    
    // Analytics view
    private var analyticsView: some View {
        HStack(spacing: 30) {
            // Clarity metric
            metricView(
                label: "Clarity",
                value: analytics["clarityImprovement"] ?? 65,
                icon: "text.magnifyingglass"
            )
            
            // Specificity metric
            metricView(
                label: "Specificity",
                value: analytics["specificityImprovement"] ?? 80,
                icon: "list.bullet.rectangle"
            )
            
            // Length change
            let lengthChange = analytics["lengthChange"] ?? 25
            let lengthIcon = lengthChange > 0 ? "arrow.up.right" : "arrow.down.right"
            let lengthValue = abs(lengthChange)
            
            metricView(
                label: "Length",
                value: lengthValue > 100 ? 100 : lengthValue,
                icon: lengthIcon
            )
        }
        .padding(.vertical, 8)
    }
    
    // Metric view
    private func metricView(label: String, value: Double, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "+%.0f%%", value))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            ProgressView(value: value, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                .frame(height: 4)
        }
    }
    
    // Action buttons
    private var actionButtonsView: some View {
        HStack {
            Button(action: {
                // Close the window without applying changes
                NSApp.keyWindow?.close()
            }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: {
                // Copy to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(enhancedPrompt, forType: .string)
                
                // Show a brief notification
                let notification = NSUserNotification()
                notification.title = "Copied to Clipboard"
                notification.informativeText = "Enhanced prompt has been copied to your clipboard."
                NSUserNotificationCenter.default.deliver(notification)
            }) {
                Text("Copy")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading || error != nil)
            
            Button(action: {
                // Apply the enhanced prompt
                onEnhance(enhancedPrompt)
                
                // Close the window
                NSApp.keyWindow?.close()
            }) {
                Text("Use Enhanced")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading || error != nil)
        }
    }
}

// Preview provider
struct PromptView_Previews: PreviewProvider {
    static var previews: some View {
        PromptView(
            originalPrompt: "Show me how to make a website",
            enhancedPrompt: "Create a step-by-step tutorial for building a responsive website using HTML5 and CSS3, including example code for basic structure, styling, and navigation. Please include best practices for cross-browser compatibility and mobile responsiveness.",
            onEnhance: { _ in }
        )
    }
}
