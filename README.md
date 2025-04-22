# PromptSage

<img src="Assets/logo.svg" width="120" height="120" alt="PromptSage Logo">

PromptSage is a lightweight Mac menu bar app that helps you craft perfect AI prompts. It observes when you're writing in any AI tool (web or native app) and offers to enhance your prompt before submission.

## Features

- **System-wide prompt detection**: Works with any AI tool, including ChatGPT, Claude, Gemini, and more
- **Intelligent prompt enhancement**: Improves clarity, specificity, and structure
- **Non-intrusive experience**: Sleek menu bar integration that stays out of your way
- **Multiple enhancement styles**: Choose from balanced, concise, detailed, technical, or creative styles
- **Various LLM providers**: Support for OpenAI, Anthropic Claude, Google Gemini, and local models via Ollama

## How It Works

1. PromptSage runs in your menu bar, monitoring for potential AI prompts
2. When you write a prompt in any AI tool, PromptSage detects it
3. A notification appears asking if you'd like to enhance the prompt
4. If you choose to enhance, PromptSage sends your prompt to an LLM for improvement
5. You can review, edit, and apply the enhanced prompt with a single click

## Screenshots

<div align="center">
  <img src="Assets/screenshot-1.png" width="600" alt="PromptSage Main Interface">
  <p><em>PromptSage Enhancement Interface</em></p>
</div>

<div align="center">
  <img src="Assets/screenshot-2.png" width="600" alt="PromptSage Preferences">
  <p><em>PromptSage Preferences</em></p>
</div>

## System Requirements

- macOS 13.0 (Monterey) or later
- Internet connection (for cloud LLM providers)
- Accessibility permissions (required for text monitoring)

## Installation

1. Download the latest release from the [Releases](https://github.com/promptsage/promptsage/releases) page
2. Move PromptSage.app to your Applications folder
3. Launch the app and follow the setup instructions
4. Grant Accessibility permissions when prompted

## Quick Start Guide

### Using Environment Variables for API Keys

PromptSage can use API keys from environment variables:

- `OPENAI_API_KEY` - For OpenAI (GPT-3.5, GPT-4, etc.)
- `ANTHROPIC_API_KEY` - For Anthropic Claude models
- `GOOGLE_API_KEY` - For Google Gemini models

For convenience, you can use the included launcher script that will prompt for your API keys and set the appropriate environment variables:

```bash
# Run the launcher script
./run_prompt_sage.sh
```

### Manual Configuration

You can also configure API keys directly in the app:

1. Click the PromptSage icon in the menu bar
2. Select "Preferences..."
3. Go to the "LLM Settings" tab
4. Choose your preferred LLM provider
5. Enter your API key

## Pricing

PromptSage offers three pricing tiers:

### Free
- 5 prompt enhancements per day
- Basic enhancement algorithms
- Single AI model (GPT-3.5)

### Pro ($8.99/month or $89.99/year)
- Unlimited prompt enhancements
- Advanced enhancement algorithms
- Multiple AI models
- Prompt history and templates
- Priority processing

### Team ($14.99/user/month)
- All Pro features
- Shared prompt libraries
- Admin dashboard
- Usage analytics
- Priority support

## Privacy

PromptSage is designed with privacy in mind:

- All text monitoring happens locally on your device
- No data is stored or analyzed without your consent
- API keys are securely stored in your system's keychain
- Option to use local models for complete privacy

## Development

### Prerequisites

- Xcode 15 or later
- Swift 5.9 or later
- macOS 13.0 SDK or later

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/promptsage/promptsage.git
cd promptsage
```

2. Open the project in Xcode:
```bash
open PromptSage.xcodeproj
```

3. Build the project (⌘B) or run (⌘R)

### Development Notes

- Use local development with Ollama for testing without API keys
- The app uses macOS Accessibility APIs for text monitoring
- API keys can be set in environment variables for development

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

PromptSage Team - info@promptsage.com

Project Link: [https://github.com/promptsage/promptsage](https://github.com/promptsage/promptsage)

Website: [https://promptsage.com](https://promptsage.com)

## Acknowledgements

- [OpenAI](https://openai.com) - For GPT models
- [Anthropic](https://anthropic.com) - For Claude models
- [Google](https://deepmind.google) - For Gemini models
- [Ollama](https://ollama.ai) - For local model integration
