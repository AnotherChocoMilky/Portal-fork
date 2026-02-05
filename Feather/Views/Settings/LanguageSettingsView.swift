import SwiftUI
import NimbleViews

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showRestartAlert = false
    @State private var selectedLanguage: AppLanguage = .english
    
    var body: some View {
        NBNavigationView(.localized("Translation")) {
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
                    Text(.localized("Select Language"))
                        .font(.system(size: 13, weight: .semibold))
                } footer: {
                    Text(.localized("Changing the language will restart the app to apply the changes."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
        .alert(.localized("Restart Required"), isPresented: $showRestartAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Restart App")) {
                changeLanguageAndRestart(to: selectedLanguage)
            }
        } message: {
            Text(.localized("The app needs to restart to change the language to %@. Do you want to continue?", selectedLanguage.displayName))
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
        TranslationService.shared.setLanguage(language.code)
        
        // Give a moment for settings to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Exit and restart the app
            exit(0)
        }
    }
}

// MARK: - Preview
#Preview {
    LanguageSettingsView()
}
