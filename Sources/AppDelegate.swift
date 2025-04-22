import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var promptDetector: PromptDetector!
    private var promptEnhancer: PromptEnhancer!
    
    // Main menu
    private var menu: NSMenu!
    
    // Window controllers
    private var preferencesWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        initializeComponents()
        checkAccessibilityPermissions()
    }
    
    // MARK: - Setup
    
    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.toolTip = "PromptSage"
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
            let notification = NSUserNotification()
            notification.title = "No Text Selected"
            notification.informativeText = "Please select text in an application to enhance it."
            NSUserNotificationCenter.default.deliver(notification)
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
        // When a potential AI prompt is detected, show a notification
        if UserDefaults.standard.bool(forKey: "ShowNotifications") {
            let notification = NSUserNotification()
            notification.title = "AI Prompt Detected"
            notification.informativeText = "Would you like to enhance this prompt?"
            notification.hasActionButton = true
            notification.actionButtonTitle = "Enhance"
            notification.otherButtonTitle = "Ignore"
            
            NSUserNotificationCenter.default.deliver(notification)
        }
        
        // If automatic enhancement is enabled, show the enhancement UI
        if UserDefaults.standard.bool(forKey: "AutomaticEnhancement") {
            presentPromptEnhancementUI(originalPrompt: prompt)
        }
    }
}

// MARK: - NSUserNotificationCenterDelegate
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if notification.activationType == .actionButtonClicked {
            if let promptText = notification.informativeText {
                presentPromptEnhancementUI(originalPrompt: promptText)
            }
        }
    }
}
