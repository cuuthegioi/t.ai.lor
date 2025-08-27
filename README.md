# Tailor

A macOS menu bar app that helps non-native English speakers improve their text using the Gemini API.

## Features

- **Global Hotkey**: Press ⌘ + ⌥ + Z to tailor selected text anywhere in macOS
- **Multiple Language Modes**: Choose from Formal, Casual, or Friendly tailoring styles
- **Inline Popover**: Clean, minimal interface that appears below selected text
- **Copy & Reload**: Easy copying of tailored text and regeneration options
- **Menu Bar App**: Runs in the background with no dock icon
- **Settings Window**: Configure language modes and view app information

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Gemini API key (for full functionality)

## Installation

1. Clone the repository
2. Open `Tailor.xcodeproj` in Xcode
3. Add your Gemini API key to `GeminiService.swift`
4. Build and run the project

## Usage

1. **Launch the app**: The app will appear in your menu bar with a scissors icon
2. **Select text**: Highlight any text in any application
3. **Press hotkey**: Use ⌘ + ⌥ + Z to trigger the tailoring
4. **Review results**: The tailored text will appear in a popover
5. **Copy or reload**: Use the buttons to copy the text or generate a new version

## Configuration

### Language Modes

- **Formal**: Professional and business-appropriate language
- **Casual**: Relaxed and informal communication  
- **Friendly**: Warm and approachable tone

### Settings

Access settings through the menu bar icon to:
- Change the default language mode
- View app information and features

## API Integration

The app uses Google's Gemini API for text tailoring. To enable full functionality:

1. Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Replace `YOUR_GEMINI_API_KEY` in `GeminiService.swift` with your actual API key
3. The app includes placeholder responses until the API key is configured

## Project Structure

```
Tailor/
├── Models/
│   └── LanguageMode.swift          # Language mode definitions
├── Views/
│   ├── TailorPopoverView.swift     # Main popover interface
│   └── SettingsView.swift          # Settings window
├── Controllers/
│   └── HotkeyManager.swift         # Global hotkey handling
├── Services/
│   ├── GeminiService.swift         # API integration
│   └── MarkdownLoader.swift        # Prompt loading
├── Resources/
│   ├── formal.md                   # Formal language prompts
│   ├── casual.md                   # Casual language prompts
│   └── friendly.md                 # Friendly language prompts
├── AppDelegate.swift               # App lifecycle management
├── SceneDelegate.swift             # Scene management
├── TailorApp.swift                 # SwiftUI app entry point
└── Info.plist                      # App configuration
```

## Architecture

The app uses a hybrid SwiftUI + AppKit architecture:
- **SwiftUI**: For modern UI components and data binding
- **AppKit**: For menu bar integration, global hotkeys, and system-level features
- **MVVM Pattern**: Clean separation of concerns with models, views, and services

## Adding New Language Modes

To add a new tailoring style:

1. Add a new case to the `LanguageMode` enum in `LanguageMode.swift`
2. Create a corresponding `.md` file in the `Resources` folder
3. The app will automatically load and use the new mode

## Development

### Building

```bash
# Open in Xcode
open Tailor.xcodeproj

# Or build from command line
xcodebuild -project Tailor.xcodeproj -scheme Tailor -configuration Debug
```

### Testing

The app includes placeholder responses for testing without an API key. The mock responses demonstrate the different language modes.

## Permissions

The app requires accessibility permissions to:
- Monitor global hotkeys
- Access selected text from other applications

These permissions will be requested when you first use the hotkey feature.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues and feature requests, please use the GitHub issues page.