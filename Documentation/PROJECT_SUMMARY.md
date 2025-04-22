# PromptSage Project Summary

## Project Overview

PromptSage is a lightweight Mac menu bar app that observes when users are writing prompts in AI tools and offers to enhance those prompts before submission, resulting in better AI outputs.

## Project Structure

```
prompt-magic/
├── Assets/                       # Source assets
│   ├── logo.svg                  # Main app logo
│   ├── MenuBarIcon.svg           # Menu bar icon (active state)
│   └── MenuBarIconInactive.svg   # Menu bar icon (inactive state)
│
├── Documentation/                # Project documentation
│   ├── Marketing_Plan.md         # Comprehensive marketing strategy
│   └── PROJECT_SUMMARY.md        # This file
│
├── PromptSage.xcodeproj/         # Xcode project
│   └── project.pbxproj           # Project configuration
│
├── Resources/                    # App resources
│   ├── Assets.xcassets/          # Asset catalog
│   │   ├── AppIcon.appiconset/   # App icon
│   │   ├── MenuBarIcon.imageset/ # Menu bar active icon
│   │   └── MenuBarIconInactive.imageset/ # Menu bar inactive icon
│   │
│   ├── Info.plist                # App configuration
│   └── MainMenu.xib              # Main menu interface
│
├── Sources/                      # Swift source code
│   ├── AppDelegate.swift         # Main app entry point
│   ├── PromptDetector.swift      # Text monitoring and prompt detection
│   ├── PromptEnhancer.swift      # LLM integration for prompt enhancement
│   ├── PromptView.swift          # SwiftUI interface for enhancement
│   └── Preferences.swift         # Preferences window UI
│
└── README.md                     # Project README
```

## Implementation Details

### Core Components

1. **AppDelegate.swift**
   - Entry point for the application
   - Sets up menu bar icon and menu
   - Coordinates other components
   - Manages app lifecycle

2. **PromptDetector.swift**
   - Monitors text input across applications
   - Detects potential AI prompts
   - Has configurable detection patterns
   - Uses Accessibility APIs

3. **PromptEnhancer.swift**
   - Connects to LLM APIs (OpenAI, Anthropic, Google, Ollama)
   - Optimizes prompts based on selected style
   - Handles API authentication and rate limiting
   - Provides analytics on improvements

4. **PromptView.swift**
   - SwiftUI interface for the enhancement window
   - Shows before/after comparison
   - Provides metrics on prompt improvements
   - Allows manual editing of enhanced prompts

5. **Preferences.swift**
   - Settings interface for the app
   - LLM provider configuration
   - Detection and enhancement preferences
   - Custom patterns and tools configuration

### Key Features

1. **System-wide Integration**
   - Works across all applications
   - Detects AI interfaces automatically
   - Accessible from menu bar

2. **Intelligent Enhancement**
   - Multiple enhancement styles (balanced, concise, detailed, etc.)
   - Support for various LLM providers
   - Analytics on improvement metrics

3. **Privacy-Focused**
   - Local processing where possible
   - Clear permissions model
   - No data retention

4. **Customization**
   - User-defined detection patterns
   - Configurable AI tools list
   - Adjustable enhancement settings

## Technical Notes

### Requirements

- macOS 13.0 (Monterey) or later
- Accessibility permissions
- Internet connection (for cloud LLMs)

### APIs Used

- macOS Accessibility API for text monitoring
- OpenAI API for GPT models
- Anthropic API for Claude models
- Google AI API for Gemini models
- Ollama API for local models

### Build Instructions

1. Open `PromptSage.xcodeproj` in Xcode
2. Configure signing identity
3. Build and run (Cmd+R)

### Deployment

The app can be distributed through:
1. Mac App Store (primary)
2. Direct download from website
3. Enterprise distribution

## Next Steps

1. Implement MainMenu.xib
2. Complete Accessibility API integration
3. Add unit and UI tests
4. Set up CI/CD pipeline
5. Create installer package
