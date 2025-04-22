import Cocoa
import SwiftUI
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var promptDetector: PromptDetector!
    private var promptEnhancer: PromptEnhancer!
    
    // Main menu
    private var menu: NSMenu!
    
    // Window controllers
    private var preferencesWindowController: NSWindowController?
    private var mainWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Add debug logging
        print("PromptSage: Application did finish launching")
        NSLog("PromptSage: Starting menu bar app")
        
        // Create and show a main window for development
        createMainWindow()
        
        setupMenuBar()
        initializeComponents()
        checkAccessibilityPermissions()
        setupNotifications()
        
        // More debug output
        print("PromptSage: Initialization complete, menu bar icon should be visible")
    }
    
    // MARK: - Setup
    
    // Create a simple main window to make the app visible during development
    private func createMainWindow() {
        let mainView = NSHostingController(rootView: MainView())
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("PromptSage")
        window.contentView = mainView.view
        window.title = "PromptSage"
        window.makeKeyAndOrderFront(nil)
        
        mainWindowController = NSWindowController(window: window)
        mainWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupMenuBar() {
        print("PromptSage: Setting up menu bar")
        
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.toolTip = "PromptSage"
            print("PromptSage: Menu bar icon set to MenuBarIcon")
        } else {
            print("PromptSage: Failed to get status item button")
        }
        
        // Create menu
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Status: Active", action: #selector(toggleActive), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Enhance Prompt", action: #selector(enhancePrompt), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit PromptSage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        // Update menu display
        updateStatusMenuItem(isActive: true)
    }
    
    private func initializeComponents() {
        // Initialize the prompt detector
        promptDetector = PromptDetector()
        promptDetector.delegate = self
        
        // Initialize the prompt enhancer with default configuration
        promptEnhancer = PromptEnhancer()
        
        // Log API key status for debugging
        logAPIKeyStatus()
    }
    
    private func logAPIKeyStatus() {
        let openaiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        let anthropicKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        let googleKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"]
        
        print("PromptSage: Environment API Keys:")
        print("  - OPENAI_API_KEY: \(openaiKey != nil ? "Found" : "Not found")")
        print("  - ANTHROPIC_API_KEY: \(anthropicKey != nil ? "Found" : "Not found")")
        print("  - GOOGLE_API_KEY: \(googleKey != nil ? "Found" : "Not found")")
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "PromptSage needs accessibility permissions to detect when you're writing prompts in AI tools. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
            }
        }
    }
    
    private func setupNotifications() {
        // Request authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("PromptSage: Notification authorization granted")
            } else if let error = error {
                print("PromptSage: Notification authorization denied: \(error.localizedDescription)")
            }
        }
        
        // Set the delegate for handling notification responses
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Actions
    
    @objc private func toggleActive(_ sender: Any) {
        let isCurrentlyActive = UserDefaults.standard.bool(forKey: "IsActive")
        let newActiveState = !isCurrentlyActive
        
        UserDefaults.standard.set(newActiveState, forKey: "IsActive")
        updateStatusMenuItem(isActive: newActiveState)
        
        // Enable/disable monitoring based on state
        if newActiveState {
            promptDetector.startMonitoring()
        } else {
            promptDetector.stopMonitoring()
        }
    }
    
    @objc private func enhancePrompt(_ sender: Any) {
        // Manually trigger prompt enhancement
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           let currentText = promptDetector.getCurrentSelectedText() {
            presentPromptEnhancementUI(originalPrompt: currentText)
        } else {
            // Show notification that no text is selected
            showNotification(
                title: "No Text Selected",
                body: "Please select text in an application to enhance it.",
                actionButtonTitle: nil
            )
        }
    }
    
    @objc private func openPreferences(_ sender: Any) {
        if preferencesWindowController == nil {
            let preferencesView = Preferences()
            let hostingController = NSHostingController(rootView: preferencesView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.center()
            window.setFrameAutosaveName("Preferences")
            window.contentView = hostingController.view
            window.title = "PromptSage Preferences"
            
            preferencesWindowController = NSWindowController(window: window)
        }
        
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func updateStatusMenuItem(isActive: Bool) {
        if let statusMenuItem = menu.item(at: 0) {
            statusMenuItem.title = isActive ? "Status: Active" : "Status: Paused"
            
            // Update the menu bar icon to show active/inactive state
            if let button = statusItem.button {
                button.image = NSImage(named: isActive ? "MenuBarIcon" : "MenuBarIconInactive")
            }
        }
    }
    
    // MARK: - Notifications
    
    private func showNotification(title: String, body: String, actionButtonTitle: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // Add prompt text to user info if needed
        if title == "AI Prompt Detected" {
            content.userInfo["promptText"] = body
        }
        
        // Create a unique identifier for the notification
        let identifier = UUID().uuidString
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("PromptSage: Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Prompt Enhancement UI
    
    func presentPromptEnhancementUI(originalPrompt: String) {
        // Create and configure the window for the prompt enhancement UI
        let promptView = PromptView(
            originalPrompt: originalPrompt,
            onEnhance: { [weak self] prompt in
                self?.processPromptEnhancement(prompt)
            }
        )
        
        let hostingController = NSHostingController(rootView: promptView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("PromptEnhancement")
        window.contentView = hostingController.view
        window.title = "Enhance Your Prompt"
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Start enhancement process
        Task {
            do {
                let enhancedPrompt = try await promptEnhancer.enhancePrompt(originalPrompt)
                await MainActor.run {
                    promptView.enhancedPrompt = enhancedPrompt
                    promptView.isLoading = false
                }
            } catch {
                await MainActor.run {
                    promptView.error = error.localizedDescription
                    promptView.isLoading = false
                }
            }
        }
    }
    
    private func processPromptEnhancement(_ prompt: String) {
        // Replace the selected text with the enhanced prompt
        promptDetector.replaceSelectedText(with: prompt)
    }
}

// MARK: - PromptDetectorDelegate
extension AppDelegate: PromptDetectorDelegate {
    func promptDetected(_ prompt: String) {
        print("PromptSage: Prompt detected: \(prompt)")
        
        // When a potential AI prompt is detected, show a notification
        if UserDefaults.standard.bool(forKey: "ShowNotifications") {
            showNotification(
                title: "AI Prompt Detected",
                body: "Would you like to enhance this prompt?",
                actionButtonTitle: "Enhance"
            )
        }
        
        // If automatic enhancement is enabled, show the enhancement UI
        if UserDefaults.standard.bool(forKey: "AutomaticEnhancement") {
            presentPromptEnhancementUI(originalPrompt: prompt)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification response
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped on the notification
            let promptText = response.notification.request.content.userInfo["promptText"] as? String
                ?? response.notification.request.content.body
            presentPromptEnhancementUI(originalPrompt: promptText)
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow the notification to be shown even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
}

// MARK: - Main View
struct MainView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("PromptSage")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
            
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 108/255, green: 92/255, blue: 231/255))
            
            Text("AI Prompt Enhancement Tool")
                .font(.headline)
            
            Text("PromptSage is running in the menu bar")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Look for the icon in your menu bar at the top of the screen.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Text("Status: Active")
                .foregroundColor(.green)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
