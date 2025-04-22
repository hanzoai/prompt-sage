#!/bin/bash

# Script to run PromptSage with environment variables for API keys

# ASCII art banner
cat << "EOF"
 ____                            _   ____                      
|  _ \ _ __ ___  _ __ ___  _ __ | |_/ ___|  __ _  __ _  ___ 
| |_) | '__/ _ \| '_ ` _ \| '_ \| __\___ \ / _` |/ _` |/ _ \
|  __/| | | (_) | | | | | | |_) | |_ ___) | (_| | (_| |  __/
|_|   |_|  \___/|_| |_| |_| .__/ \__|____/ \__,_|\__, |\___|
                          |_|                    |___/      
EOF

echo "PromptSage Launcher"
echo "==================="
echo

# Check if API keys are already set in environment
if [ -z "$OPENAI_API_KEY" ]; then
    read -p "Enter your OpenAI API key (leave blank to skip): " OPENAI_API_KEY
    export OPENAI_API_KEY
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    read -p "Enter your Anthropic API key (leave blank to skip): " ANTHROPIC_API_KEY
    export ANTHROPIC_API_KEY
fi

if [ -z "$GOOGLE_API_KEY" ]; then
    read -p "Enter your Google AI API key (leave blank to skip): " GOOGLE_API_KEY
    export GOOGLE_API_KEY
fi

# Set default LLM provider based on available keys
if [ -n "$OPENAI_API_KEY" ]; then
    defaults write com.promptsage.app LLMProvider "OpenAI"
    echo "Default provider set to OpenAI"
elif [ -n "$ANTHROPIC_API_KEY" ]; then
    defaults write com.promptsage.app LLMProvider "Anthropic Claude"
    echo "Default provider set to Anthropic Claude"
elif [ -n "$GOOGLE_API_KEY" ]; then
    defaults write com.promptsage.app LLMProvider "Google Gemini"
    echo "Default provider set to Google Gemini"
else
    defaults write com.promptsage.app LLMProvider "Local (Ollama)"
    echo "No API keys provided. Default provider set to Local (Ollama)"
fi

# Run the app
echo
echo "Launching PromptSage..."
open "/Applications/PromptSage.app"

# If app is not in Applications folder, try running from the current directory
if [ $? -ne 0 ]; then
    APP_PATH=$(find . -name "PromptSage.app" -type d -maxdepth 3)
    if [ -n "$APP_PATH" ]; then
        echo "PromptSage not found in Applications folder. Running from $APP_PATH"
        open "$APP_PATH"
    else
        echo "Error: PromptSage.app not found. Please make sure the app is installed."
        exit 1
    fi
fi

echo
echo "PromptSage is running in the menu bar. Look for the icon at the top of your screen."
echo "You can now close this terminal window."
