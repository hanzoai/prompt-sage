# PromptSage Project Architecture

## Overview

PromptSage is a macOS menu bar application that detects when users are writing prompts in AI tools and offers to enhance those prompts before submission. The application is designed to work system-wide across different applications and supports multiple LLM providers including OpenAI, Anthropic, Google AI, and local models via Ollama.

## Core Architecture Components

### 1. Application Structure

The application follows a modular architecture with clear separation of concerns:

- **AppDelegate**: Central coordinator that manages the application lifecycle, menu bar integration, and component orchestration
- **PromptDetector**: Monitors text input across applications to detect potential AI prompts
- **PromptEnhancer**: Handles LLM integration for prompt enhancement using various providers
- **PromptView**: SwiftUI interface for displaying and editing enhanced prompts
- **Preferences**: User settings management for LLM providers, API keys, and detection preferences

### 2. Component Interactions

```
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│  AppDelegate    │◄────┤  User Settings  │
│                 │     │                 │
└────────┬────────┘     └─────────────────┘
         │
         │ coordinates
         ▼
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│ PromptDetector  │────►│  PromptView     │
│                 │     │                 │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │ sends prompts         │ requests
         ▼                       ▼
┌─────────────────────────────────────────┐
│                                         │
│            PromptEnhancer               │
│                                         │
└─────────────────────────────────────────┘
              │
              │ connects to
              ▼
┌─────────────────────────────────────────┐
│                                         │
│       LLM Provider APIs                 │
│  (OpenAI, Anthropic, Google, Ollama)    │
│                                         │
└─────────────────────────────────────────┘
```

### 3. Data Flow

1. **Prompt Detection**:
   - PromptDetector monitors keyboard input and active applications
   - When potential AI prompt is detected, the delegate is notified
   - AppDelegate receives notification and initiates the enhancement process

2. **Prompt Enhancement**:
   - PromptView is presented to the user with the original prompt
   - PromptEnhancer sends the prompt to the configured LLM provider
   - Enhanced prompt is returned and displayed in PromptView
   - User can edit and apply the enhanced prompt

3. **Settings Management**:
   - Preferences window allows configuration of LLM providers, API keys, etc.
   - Settings are stored in UserDefaults
   - AppDelegate updates components when settings change

## Technical Implementation Details

### 1. Text Monitoring

The application uses macOS Accessibility APIs to monitor text input across applications:
- Event tap to monitor keystrokes
- Text buffer to accumulate observed text
- Pattern matching to identify AI tools and potential prompts
- Detection logic to determine when a complete prompt is ready for enhancement

### 2. LLM Integration

The application supports multiple LLM providers through a unified interface:
- Provider-specific API integration (OpenAI, Anthropic, Google, Ollama)
- Configuration options for model selection, temperature, etc.
- System prompts customized for different enhancement styles
- Error handling for API issues, rate limiting, etc.

### 3. User Interface

The application uses SwiftUI for modern macOS UI components:
- Menu bar icon with dropdown menu
- Preferences window with tabbed interface
- Prompt enhancement dialog with before/after comparison
- Analytics display for prompt improvements

## Key Design Decisions

### 1. Menu Bar Integration

The application is designed as a menu bar app for several reasons:
- Always accessible without cluttering the desktop
- Minimal resource usage when not active
- Non-intrusive user experience
- Familiar pattern for macOS utility applications

### 2. System-Wide Monitoring

The application uses Accessibility APIs rather than browser extensions:
- Works across all applications, not just web browsers
- Supports native AI tools and not just web interfaces
- More flexible detection capabilities
- Consistent user experience across different tools

### 3. Multiple LLM Provider Support

The application supports various LLM providers to:
- Give users choice based on their existing API access
- Allow for different capabilities and specializations
- Provide local options for privacy (via Ollama)
- Future-proof the application as the LLM landscape evolves

### 4. Enhancement Styles

The application offers different enhancement styles to:
- Accommodate different user needs and preferences
- Optimize for specific use cases (technical, creative, etc.)
- Provide flexibility in how prompts are improved
- Allow experimentation with different enhancement approaches

## Implementation Challenges

### 1. Text Monitoring Limitations

- Detecting AI interfaces reliably across different applications
- Balancing buffer size to capture complete prompts without excessive memory usage
- Minimizing performance impact of keystroke monitoring
- Privacy considerations for text monitoring

### 2. API Key Management

- Securely storing API keys in the keychain
- Supporting environment variables for easier configuration
- Handling expired or invalid API keys gracefully
- Managing rate limits for different providers

### 3. User Experience Considerations

- Providing non-intrusive yet accessible prompt enhancement
- Balancing automatic detection with manual activation
- Giving useful feedback on prompt improvements
- Making enhancement styles intuitive and useful

## Development Roadmap

### 1. Current Implementation Status

- Basic menu bar integration and UI components
- LLM provider integration framework
- Text monitoring infrastructure
- Settings management

### 2. Pending Implementation Items

- Complete Accessibility API integration for robust text monitoring
- Keychain integration for secure API key storage
- Environment variable support for API keys
- Clipboard handling for prompt replacement
- Comprehensive error handling

### 3. Future Enhancements

- Support for additional LLM providers
- Advanced prompt templates and patterns
- Prompt history and favorites
- Analytics dashboard for enhancement metrics
- Team sharing features
- Cross-platform support (Windows, Linux)

## Development Practices

- SwiftUI for modern UI development
- Protocol-oriented design for flexibility and testability
- Separation of concerns for maintainability
- Extensive error handling for robustness
- User-centric design for intuitive experience
