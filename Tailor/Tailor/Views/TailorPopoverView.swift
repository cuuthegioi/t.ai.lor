import SwiftUI

struct TailorPopoverView: View {
    let originalText: String?
    @State private var tailoredText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @AppStorage("selectedLanguageMode") private var selectedLanguageMode: LanguageMode = .formal
    
    init(originalText: String? = nil) {
        self.originalText = originalText
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let originalText = originalText {
                // Show tailored text interface
                VStack(alignment: .leading, spacing: 12) {
                    Text("Original Text")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(originalText)
                        .font(.body)
                        .padding(8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    
                    Divider()
                    
                    Text("Tailored Text")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Tailoring text...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Text(tailoredText.isEmpty ? "Click 'Tailor' to generate improved text" : tailoredText)
                            .font(.body)
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Copy") {
                        copyToClipboard()
                    }
                    .disabled(tailoredText.isEmpty || isLoading)
                    
                    Button("Reload") {
                        tailorText()
                    }
                    .disabled(isLoading)
                    
                    Spacer()
                }
            } else {
                // Show welcome interface
                VStack(spacing: 16) {
                    Image(systemName: "scissors")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Tailor")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select text anywhere and press ⌘ + ⌥ + Z to tailor it")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Current Mode: \(selectedLanguageMode.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            if originalText != nil {
                tailorText()
            }
        }
    }
    
    private func tailorText() {
        guard let originalText = originalText else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await GeminiService.shared.tailorText(originalText, languageMode: selectedLanguageMode)
                await MainActor.run {
                    tailoredText = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(tailoredText, forType: .string)
    }
}

#Preview {
    TailorPopoverView(originalText: "This is a sample text to tailor.")
} 