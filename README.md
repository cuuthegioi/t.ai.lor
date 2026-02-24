# Tailor

> **Note:** I don’t know Swift—this was vibe-coded. The structure and style may be non-idiomatic. Improvements welcome.

A macOS menu bar app that helps non-native English speakers improve their text. Copy text to the clipboard, press a hotkey, and get a polished version from ChatGPT or Gemini.

## Features

- **Menu bar app** – Runs in the background with a scissors icon; no Dock icon
- **Global hotkey** – ⌘ + ⌥ + Z to tailor whatever is on the clipboard
- **Two AI providers** – Choose **ChatGPT** (OpenAI) or **Gemini** in the menu (default: ChatGPT)
- **Bring your own key** – Set your API key via **Tailor → Set API Key…**; stored in the system Keychain
- **Result panel** – Tailored text in an editable panel; copy with the button or ⌘C, then OK to copy and close

## Requirements

- macOS 13.0 or later
- Swift 5.9+ (Xcode or Swift CLI)
- An API key for OpenAI (ChatGPT) and/or Google (Gemini)

## Installation

1. Clone the repo.
2. Build: `swift build -c release`
3. Run the binary, or create an app bundle and DMG (see [Development](#development) below).
4. On first run, open the menu bar icon → **Set API Key…** and paste your key (stored in Keychain).

## Usage

1. **Launch** – Run Tailor; the scissors icon appears in the menu bar.
2. **Set API key** – Menu bar → **Tailor → Set API Key…** → paste key → Save.
3. **Choose provider** – **Tailor → ChatGPT** or **Tailor → Gemini** (checkmark shows current).
4. **Tailor text** – Copy some text (⌘C), then press **⌘⌥Z**. The app reads the clipboard, calls the selected AI, and shows the result in a panel.
5. **Copy result** – Use **Copy** or **OK** (OK copies and closes). You can edit the text in the panel before copying.

## Permissions

- **Accessibility** – Required for the global hotkey (⌘⌥Z). If the hotkey doesn’t work, add Tailor (or Terminal/iTerm if you run from CLI) in **System Settings → Privacy & Security → Accessibility**.

## Project structure

```
Sources/Tailor/
├── main.swift           # App entry, menu bar, hotkey, panels
├── GPTService.swift     # OpenAI (gpt-4o-mini) tailor API
├── GeminiService.swift  # Google Gemini tailor API
├── TailorPrompt.swift   # Shared system prompt for tailoring
└── KeychainStorage.swift # API key save/load via Keychain
```

- **TailorPrompt** – Single shared prompt (improve text for non-native English; output only revised text).
- **Keychain** – API key is stored with the Security framework; no config files.

## Development

### Build and run

```bash
swift build -c release
.build/release/Tailor
```

Or debug build: `swift build` then `swift run Tailor`.

### App bundle and DMG

To get a double-clickable app and a DMG for other Macs:

1. After `swift build -c release`, create the app bundle (e.g. copy binary into `Tailor.app/Contents/MacOS/` and add `Contents/Info.plist` with `CFBundleExecutable`, `LSUIElement` = true, etc.).
2. Create a DMG: e.g. `hdiutil create -volname "Tailor" -srcfolder Tailor.app -ov -format UDZO Tailor.dmg`.

On another Mac, if the app is **unsigned**, Gatekeeper may show “damaged”. Use **Right-click → Open** once, or run: `xattr -cr Tailor.app`. For distribution, sign and notarize with an Apple Developer ID.

## License

MIT.
