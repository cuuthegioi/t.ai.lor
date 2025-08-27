import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguageMode") private var selectedLanguageMode: LanguageMode = .formal
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                Button("Settings") {
                    selectedTab = 0
                }
                .buttonStyle(TabButtonStyle(isSelected: selectedTab == 0))
                
                Button("About") {
                    selectedTab = 1
                }
                .buttonStyle(TabButtonStyle(isSelected: selectedTab == 1))
                
                Spacer()
            }
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Tab content
            if selectedTab == 0 {
                SettingsTabView(selectedLanguageMode: $selectedLanguageMode)
            } else {
                AboutTabView()
            }
        }
    }
}

struct SettingsTabView: View {
    @Binding var selectedLanguageMode: LanguageMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Language Mode")
                    .font(.headline)
                
                Text("Choose how you want your text to be tailored:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(LanguageMode.allCases) { mode in
                        HStack {
                            Button(action: {
                                selectedLanguageMode = mode
                            }) {
                                HStack {
                                    Image(systemName: selectedLanguageMode == mode ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedLanguageMode == mode ? .blue : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.displayName)
                                            .font(.body)
                                            .fontWeight(selectedLanguageMode == mode ? .semibold : .regular)
                                        
                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct AboutTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scissors")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Tailor")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("An app to help non-native English speakers improve their text using AI.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Features:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Global hotkey (⌘ + ⌥ + Z) for quick access")
                    Text("• Multiple language modes (Formal, Casual, Friendly)")
                    Text("• Inline popover interface")
                    Text("• Copy tailored text to clipboard")
                    Text("• Menu bar app with no dock icon")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct TabButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .font(.body)
            .fontWeight(isSelected ? .semibold : .regular)
    }
}

#Preview {
    SettingsView()
} 