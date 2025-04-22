import Cocoa
import Foundation
import Carbon.HIToolbox

// Protocol for prompt detection events
protocol PromptDetectorDelegate: AnyObject {
    func promptDetected(_ prompt: String)
}

class PromptDetector {
    // Delegate to receive detection events
    weak var delegate: PromptDetectorDelegate?
    
    // Event tap for monitoring keystrokes
    private var eventTap: CFMachPort?
    
    // Observed text buffers
    private var textBuffer = ""
    private let maxBufferSize = 2000
    
    // AI tool detection patterns
    private var aiToolPatterns = [
        // OpenAI ChatGPT
        "chat.openai.com",
        // Google Bard/Gemini
        "gemini.google.com",
        "bard.google.com",
        // Anthropic Claude
        "claude.ai",
        // Microsoft Copilot
        "copilot.microsoft.com",
        // Popular AI platforms and IDE extensions
        "github.com/features/copilot",
        "perplexity.ai",
        "huggingface.co/chat",
        // More can be added through user preferences
    ]
    
    // Prompt detection patterns
    private var promptPatterns = [
        // OpenAI ChatGPT UI pattern
        "<textarea[^>]*placeholder=\"[^\"]*\"[^>]*>(.*?)</textarea>",
        // Generic text area pattern
        "write a .* for",
        "create a .* that",
        "generate .* example",
        "explain how to",
        "help me with",
        "show me how",
        "tell me about",
    ]
    
    // Initialize detector
    init() {
        loadUserDefinedPatterns()
    }
    
    // Load user-defined patterns from preferences
    private func loadUserDefinedPatterns() {
        if let customAITools = UserDefaults.standard.stringArray(forKey: "CustomAITools") {
            aiToolPatterns.append(contentsOf: customAITools)
        }
        
        if let customPromptPatterns = UserDefaults.standard.stringArray(forKey: "CustomPromptPatterns") {
            promptPatterns.append(contentsOf: customPromptPatterns)
        }
    }
    
    // MARK: - Text Monitoring
    
    func startMonitoring() {
        // Create an event tap to monitor keystrokes
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        eventTap = tap
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("PromptDetector: Started monitoring")
    }
    
    func stopMonitoring() {
        // Disable and release the event tap
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
            
            print("PromptDetector: Stopped monitoring")
        }
    }
    
    // Event tap callback
    private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        guard let userInfo = userInfo else {
            return Unmanaged.passRetained(event)
        }
        
        let detector = Unmanaged<PromptDetector>.fromOpaque(userInfo).takeUnretainedValue()
        return detector.handleEvent(proxy: proxy, type: type, event: event)
    }
    
    // Handle events from the tap
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        if type == .keyDown {
            // Process key down events
            if let unicodeString = event.unicodeString {
                updateTextBuffer(with: unicodeString)
            }
        }
        
        // Pass the event through unchanged
        return Unmanaged.passRetained(event)
    }
    
    // Update the text buffer with new input
    private func updateTextBuffer(with string: String) {
        textBuffer.append(string)
        
        // Trim buffer if it exceeds max size
        if textBuffer.count > maxBufferSize {
            textBuffer = String(textBuffer.suffix(maxBufferSize))
        }
        
        // Check if the current application is an AI tool
        if isAIToolActive() {
            // Check if the text buffer contains a potential prompt
            if let prompt = detectPrompt() {
                delegate?.promptDetected(prompt)
                
                // Clear buffer after detection
                textBuffer = ""
            }
        }
    }
    
    // MARK: - Detection Logic
    
    // Check if the active application is an AI tool
    private func isAIToolActive() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        
        // Check if it's a browser first
        if isBrowser(frontmostApp) {
            // For browsers, check the current URL
            return isAIToolURL(getCurrentURL())
        }
        
        // Check if it's a known AI-enabled application
        let aiEnabledApps = [
            "com.microsoft.VSCode", // Visual Studio Code (might have Copilot)
            "com.jetbrains.intellij", // IntelliJ (might have AI assistants)
            "com.github.GitHubClient", // GitHub Desktop
            // Add more known AI-enabled application bundle IDs
        ]
        
        return aiEnabledApps.contains(frontmostApp.bundleIdentifier ?? "")
    }
    
    // Check if an application is a web browser
    private func isBrowser(_ app: NSRunningApplication) -> Bool {
        let browserBundleIDs = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera",
        ]
        
        return browserBundleIDs.contains(app.bundleIdentifier ?? "")
    }
    
    // Get the current URL from the browser
    private func getCurrentURL() -> String {
        // This would typically use AppleScript to get the URL from the browser
        // For this example, we'll simulate it
        
        // In a real implementation, we would use something like:
        /*
        let script = NSAppleScript(source: """
            tell application "Safari"
                return URL of current tab of front window
            end tell
            """)
        
        var error: NSDictionary?
        if let result = script?.executeAndReturnError(&error) {
            return result.stringValue ?? ""
        }
        */
        
        // Simulate URL detection for now
        for pattern in aiToolPatterns {
            if textBuffer.contains(pattern) {
                return pattern
            }
        }
        
        return ""
    }
    
    // Check if a URL is for an AI tool
    private func isAIToolURL(_ url: String) -> Bool {
        for pattern in aiToolPatterns {
            if url.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    // Detect if the buffer contains a prompt
    private func detectPrompt() -> String? {
        // Check for common prompt patterns
        for pattern in promptPatterns {
            if let range = textBuffer.range(of: pattern, options: .regularExpression) {
                // Get the last paragraph or sentence as the potential prompt
                let prompt = extractPrompt(around: range)
                
                // Verify it looks like a complete prompt
                if isLikelyPrompt(prompt) {
                    return prompt
                }
            }
        }
        
        // Additional heuristics for detecting prompts in AI interfaces
        // Check for textarea content in web interfaces
        if textBuffer.contains("<textarea") && textBuffer.contains("</textarea>") {
            if let prompt = extractTextAreaContent() {
                return prompt
            }
        }
        
        return nil
    }
    
    // Extract a prompt around a matching pattern
    private func extractPrompt(around range: Range<String.Index>) -> String {
        // Get the paragraph containing the match
        let startOfParagraph = textBuffer[..<range.lowerBound].lastIndex(of: "\n") ?? textBuffer.startIndex
        let endOfParagraph = textBuffer[range.upperBound...].firstIndex(of: "\n") ?? textBuffer.endIndex
        
        // Extract the paragraph
        let startIndex = startOfParagraph == textBuffer.startIndex ? startOfParagraph : textBuffer.index(after: startOfParagraph)
        let promptRange = startIndex..<endOfParagraph
        
        return String(textBuffer[promptRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Extract content from HTML textarea tags
    private func extractTextAreaContent() -> String? {
        // Simple regex to extract content from textarea tags
        let pattern = "<textarea[^>]*>(.*?)</textarea>"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            let nsRange = NSRange(textBuffer.startIndex..., in: textBuffer)
            
            if let match = regex.firstMatch(in: textBuffer, options: [], range: nsRange) {
                if match.numberOfRanges > 1, let contentRange = Range(match.range(at: 1), in: textBuffer) {
                    return String(textBuffer[contentRange])
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return nil
    }
    
    // Determine if text is likely a complete prompt
    private func isLikelyPrompt(_ text: String) -> Bool {
        // Minimum length for a meaningful prompt
        if text.count < 10 {
            return false
        }
        
        // Check if it ends with common punctuation
        let endsWithPunctuation = [".","?","!"].contains { text.hasSuffix($0) }
        
        // Check if it has multiple words
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count < 3 {
            return false
        }
        
        // Check if it contains common prompt language
        let promptWords = ["create", "write", "generate", "explain", "help", "show", "tell", "make", "design"]
        let containsPromptWord = promptWords.contains { text.localizedCaseInsensitiveContains($0) }
        
        return (endsWithPunctuation || containsPromptWord)
    }
    
    // MARK: - Text Manipulation Utilities
    
    // Get the currently selected text
    func getCurrentSelectedText() -> String? {
        // This would typically use Accessibility APIs to get selected text
        // For this example, we'll simulate it
        
        // In a real implementation, we would use something like:
        /*
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        let _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if let focusedElement = focusedElement {
            var value: AnyObject?
            let _ = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &value)
            
            if let selectedText = value as? String {
                return selectedText
            }
        }
        */
        
        // Simulate text selection for now
        if !textBuffer.isEmpty {
            return textBuffer
        }
        
        return nil
    }
    
    // Replace the selected text with new text
    func replaceSelectedText(with newText: String) {
        // This would typically use Accessibility APIs to replace selected text
        // For this example, we'll simulate it
        
        // In a real implementation, we would use something like:
        /*
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        let _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if let focusedElement = focusedElement {
            let _ = AXUIElementSetAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, newText as CFTypeRef)
        }
        */
        
        // Simulate text replacement for now
        textBuffer = newText
        
        // In a real implementation, we might use keystrokes to simulate copy/paste:
        /*
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        // Set clipboard to new text
        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)
        
        // Simulate CMD+V
        let vKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true)
        vKeyDown?.flags = .maskCommand
        vKeyDown?.post(tap: .cghidEventTap)
        
        let vKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false)
        vKeyUp?.flags = .maskCommand
        vKeyUp?.post(tap: .cghidEventTap)
        
        // Restore clipboard
        pasteboard.clearContents()
        if let oldContents = oldContents {
            pasteboard.setString(oldContents, forType: .string)
        }
        */
    }
}

// Extension for CGEvent to get string representation
extension CGEvent {
    var unicodeString: String? {
        guard type == .keyDown || type == .keyUp else { return nil }
        
        // Define variables for UCKeyTranslate
        let maxStringLength = 4
        var chars = [UniChar](repeating: 0, count: maxStringLength)
        
        // Skip keyboard layout processing for now due to complexity
        // In a real implementation, we would use UCKeyTranslate to convert the keycode
        
        // For now, let's return a simple character based on the keycode
        // This is a simplified approach just to get the app to compile
        let keycode = getIntegerValueField(.keyboardEventKeycode)
        
        // Simple mapping of common keys
        switch keycode {
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 31: return "o"
        case 32: return "u"
        case 33: return "i"
        case 34: return "p"
        case 35: return "l"
        case 36: return "\n"  // Return key
        case 37: return "j"
        case 38: return "k"
        case 39: return ";"
        case 40: return "\\"
        case 41: return ","
        case 42: return "/"
        case 43: return "n"
        case 44: return "m"
        case 45: return "."
        case 46: return "\t"  // Tab key
        case 49: return " "   // Space key
        case 50: return "`"
        default:
            return nil
        }
    }
}

// NSUserNotification is deprecated in macOS 11.0+
// Use UNUserNotificationCenter on macOS 11.0+ instead
@available(macOS, deprecated: 11.0, message: "Use UserNotifications framework's UNUserNotificationCenter instead")
extension AppDelegate: NSUserNotificationCenterDelegate {
    @available(macOS, deprecated: 11.0, message: "Use UserNotifications framework's UNUserNotificationCenter instead")
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if notification.activationType == .actionButtonClicked {
            if let promptText = notification.informativeText {
                presentPromptEnhancementUI(originalPrompt: promptText)
            }
        }
    }
}
