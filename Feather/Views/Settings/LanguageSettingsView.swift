import SwiftUI
import NimbleViews

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showRestartAlert = false
    @State private var selectedLanguage: AppLanguage = .english
    
    var body: some View {
        NBNavigationView("Translation") {
            List {
                Section {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button {
                            selectedLanguage = language
                            showRestartAlert = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(language.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(language.nativeName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if appLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Select Language")
                        .font(.system(size: 13, weight: .semibold))
                } footer: {
                    Text("Changing the language will restart the app to apply the changes.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restart App") {
                changeLanguageAndRestart(to: selectedLanguage)
            }
        } message: {
            Text("The app needs to restart to change the language to \(selectedLanguage.displayName). Do you want to continue?")
        }
        .onAppear {
            // Set current language on appear
            if let currentLang = AppLanguage.allCases.first(where: { $0.code == appLanguage }) {
                selectedLanguage = currentLang
            }
        }
    }
    
    private func changeLanguageAndRestart(to language: AppLanguage) {
        // Save the language preference
        appLanguage = language.code
        UserDefaults.standard.set([language.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Give a moment for settings to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Exit and restart the app
            exit(0)
        }
    }
}

// MARK: - App Language Enum
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    
    var code: String {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

// MARK: - Preview
#Preview {
    LanguageSettingsView()
}
