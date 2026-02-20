//
//  SettingsView.swift
//  Lektüren
//
//  Einstellungen für die App, inkl. Claude AI API-Key.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("claudeAPIKey") private var claudeAPIKey: String = ""
    @AppStorage("enableAIExtraction") private var enableAIExtraction: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    @State private var isTestingAPI = false
    @State private var testResult: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("AI-Metadaten-Extraktion aktivieren", isOn: $enableAIExtraction)
                } header: {
                    Text("Automatische Extraktion")
                } footer: {
                    Text("Beim Import von PDFs werden automatisch Titel, Autor, Datum, Zusammenfassung und Keywords mit Claude AI extrahiert.")
                }
                
                Section {
                    SecureField("API-Key eingeben", text: $claudeAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                    #endif
                    
                    if !claudeAPIKey.isEmpty {
                        Button {
                            testAPIConnection()
                        } label: {
                            HStack {
                                if isTestingAPI {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text("Verbindung testen")
                            }
                        }
                        .disabled(isTestingAPI)
                    }
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(result.contains("✅") ? .green : .red)
                    }
                } header: {
                    Text("Claude API")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benötigt einen API-Key von Anthropic.")
                        Link("API-Key erstellen →", destination: URL(string: "https://console.anthropic.com/")!)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Was wird extrahiert?")
                            .font(.headline)
                        
                        Label("Titel des Dokuments", systemImage: "doc.text")
                        Label("Autor / Organisation", systemImage: "person")
                        Label("Erstellungsdatum", systemImage: "calendar")
                        Label("Zusammenfassung (max. 240 Wörter)", systemImage: "text.alignleft")
                        Label("Keywords / Tags", systemImage: "tag")
                    }
                    .font(.subheadline)
                } header: {
                    Text("Informationen")
                }
            }
            .navigationTitle("Einstellungen")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func testAPIConnection() {
        isTestingAPI = true
        testResult = nil
        
        Task {
            do {
                // Einfacher Test-Request an die Claude API
                let url = URL(string: "https://api.anthropic.com/v1/messages")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Probiere verschiedene Model-Namen aus
                let modelsToTry = [
                    "claude-sonnet-4-6",
//                    "claude-3-5-sonnet-20250220",  // Aktuelles Datum-basiertes Model
//                    "claude-3-5-sonnet-20241022",  // Vorheriges Model
//                    "claude-3-opus-20240229",      // Stabiles Opus-Model
//                    "claude-3-sonnet-20240229",    // Stabiles Sonnet-Model
//                    "claude-3-haiku-20240307"      // Haiku als Fallback
                ]
                
                print("🔍 [API Test] Versuche verschiedene Models...")
                
                var lastError: String = ""
                for modelName in modelsToTry {
                    let testRequest = ClaudeRequest(
                        model: modelName,
                        maxTokens: 10,
                        messages: [ClaudeMessage(role: "user", content: "Hi")]
                    )
                    
                    var testUrlRequest = request
                    testUrlRequest.httpBody = try JSONEncoder().encode(testRequest)
                    
                    print("🔍 [API Test] Teste Model: \(modelName)")
                    
                    let (data, response) = try await URLSession.shared.data(for: testUrlRequest)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            testResult = "✅ Verbindung erfolgreich (Model: \(modelName))"
                            print("✅ [API Test] Erfolgreich mit Model: \(modelName)")
                            
                            // Speichere das funktionierende Model
                            UserDefaults.standard.set(modelName, forKey: "workingClaudeModel")
                            isTestingAPI = false
                            return
                        } else {
                            let errorBody = String(data: data, encoding: .utf8) ?? ""
                            lastError = "HTTP \(httpResponse.statusCode): \(errorBody)"
                            print("❌ [API Test] Model \(modelName) fehlgeschlagen: \(httpResponse.statusCode)")
                        }
                    }
                }
                
                // Kein Model hat funktioniert
                testResult = "❌ Kein gültiges Model gefunden. Letzter Fehler: \(lastError)"
                print("❌ [API Test] Alle Models fehlgeschlagen")
            } catch {
                let errorMsg = error.localizedDescription
                testResult = "❌ Fehler: \(errorMsg)"
                print("❌ [API Test] Exception: \(errorMsg)")
                print("❌ [API Test] Error Details: \(error)")
            }
            
            isTestingAPI = false
        }
    }
}

#Preview {
    SettingsView()
}
